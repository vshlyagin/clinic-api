require "swagger_helper"

RSpec.describe "api/v1/patients", type: :request do
  path "/api/v1/patients" do
    get("Список пациентов") do
      tags "patients"
      produces "application/json"

      response(200, "Список пациентов") do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {"$ref" => "#/components/schemas/Patient"}
            }
          }

        let!(:patient) do
          Patient.create!(
            first_name: "Иван",
            middle_name: "Иванович",
            last_name: "Петров",
            birthday: Date.new(1990, 1, 1),
            gender: true,
            height: 180,
            weight: 75
          )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          data = body["data"].first

          expect(data["id"]).to eq(patient.id)
          expect(data["first_name"]).to eq("Иван")
          expect(data["middle_name"]).to eq("Иванович")
          expect(data["last_name"]).to eq("Петров")
          expect(data["gender"]).to eq(true)
        end
      end
    end

    post("Создать пациента") do
      tags "patients"
      consumes "application/json"
      produces "application/json"
      parameter name: :patient, in: :body, schema: {"$ref" => "#/components/schemas/Patient"}

      response(201, "Пациент создан") do
        let(:patient) do
          {
            first_name: "Петр",
            middle_name: "Петрович",
            last_name: "Сидоров",
            birthday: "1995-05-05",
            gender: true,
            height: 175,
            weight: 70
          }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          data = body["data"]

          expect(data["first_name"]).to eq("Петр")
          expect(data["middle_name"]).to eq("Петрович")
          expect(data["last_name"]).to eq("Сидоров")
        end
      end

      response(422, "Некорректные данные") do
        let(:patient) { { first_name: "" } }
        run_test!
      end
    end
  end

  path "/api/v1/patients/{patient_id}" do
    get("Показать пациента") do
      tags "patients"
      produces "application/json"
      parameter name: :patient_id, in: :path, type: :integer

      let!(:patient) do
        Patient.create!(
          first_name: "Иван",
          middle_name: "Иванович",
          last_name: "Петров",
          birthday: Date.new(1990, 1, 1),
          gender: true,
          height: 180,
          weight: 75
        )
      end
      let(:patient_id) { patient.id }

      response(200, "Пациент найден") do
        run_test! do |response|
          body = JSON.parse(response.body)
          data = body["data"]
          expect(data["id"]).to eq(patient.id)
        end
      end

      response(404, "Пациент не найден") do
        let(:patient_id) { 0 }
        run_test!
      end
    end

    patch("Обновить пациента") do
      tags "patients"
      consumes "application/json"
      produces "application/json"
      parameter name: :patient, in: :body, schema: {"$ref" => "#/components/schemas/Patient"}

      let!(:patient) do
        Patient.create!(
          first_name: "Иван",
          middle_name: "Иванович",
          last_name: "Петров",
          birthday: Date.new(1990, 1, 1),
          gender: true,
          height: 180,
          weight: 75
        )
      end
      let(:patient_id) { patient.id }
      let(:patient) { { first_name: "Пётр", weight: 80 } }

      response(200, "Пациент обновлён") do
        run_test! do
          updated = Patient.find(patient_id)
          expect(updated.first_name).to eq("Пётр")
          expect(updated.weight).to eq(80)
        end
      end

      response(422, "Некорректные данные") do
        let(:patient) { { first_name: "" } }
        run_test!
      end
    end

    delete("Удалить пациента") do
      tags "patients"
      produces "application/json"
      parameter name: :patient_id, in: :path, type: :integer

      let!(:patient) do
        Patient.create!(
          first_name: "Иван",
          middle_name: "Иванович",
          last_name: "Петров",
          birthday: Date.new(1990, 1, 1),
          gender: true,
          height: 180,
          weight: 75
        )
      end
      let(:patient_id) { patient.id }

      response(204, "Пациент удалён") do
        run_test! do
          expect(Patient.find_by(id: patient_id)).to be_nil
        end
      end

      response(404, "Пациент не найден") do
        let(:patient_id) { 0 }
        run_test!
      end
    end
  end

  path "/api/v1/patients/{patient_id}/calculate_bmr" do
    post("Рассчитать BMR") do
      tags "patients"
      consumes "application/json"
      produces "application/json"
      parameter name: :patient_id, in: :path, type: :integer
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          formula: { type: :string, enum: %w[mifflin harris] }
        },
        required: %w[formula]
      }

      let!(:patient) do
        Patient.create!(
          first_name: "Иван",
          middle_name: "Иванович",
          last_name: "Петров",
          birthday: Date.new(1990, 1, 1),
          gender: true,
          height: 180,
          weight: 75
        )
      end
      let(:patient_id) { patient.id }
      let(:body) { { formula: "mifflin" } }

      response(201, "Рассчёт выполнен и сохранён") do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["patient_id"]).to eq(patient.id)
          expect(data["formula"]).to eq("mifflin")
          expect(data["result"]).to be_a(Float).or be_a(Integer)
        end
      end

      response(422, "Некорректные данные") do
        let(:body) { { formula: "unknown_formula" } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Unknown formula")
        end
      end
    end
  end
end