require "swagger_helper"

RSpec.describe "api/v1/patients", type: :request do
  path '/api/v1/patients' do
    get("Список пациентов") do
      tags "patients"
      produces "application/json"
  
      parameter name: :full_name, in: :query, type: :string, description: "Фильтр по полному имени"
      parameter name: :gender, in: :query, type: :boolean, description: "Фильтр по полу"
      parameter name: :start_age, in: :query, type: :integer, description: "Минимальный возраст"
      parameter name: :end_age, in: :query, type: :integer, description: "Максимальный возраст"
      parameter name: :limit, in: :query, type: :integer, description: "Лимит на количество записей"
      parameter name: :offset, in: :query, type: :integer, description: "Смещение для пагинации"
  
      response(200, "Список пациентов") do
        schema type: :object,
          properties: {
            patients: {
              type: :array,
              items: {"$ref" => "#/components/schemas/Patient"}
            }
          }
  
        let!(:patient1) do
          Patient.create!(first_name: "Иван", middle_name: "Иванович", last_name: "Петров",
                          birthday: 30.years.ago, gender: true, height: 180, weight: 75)
        end
        let!(:patient2) do
          Patient.create!(first_name: "Петр", middle_name: "Петрович", last_name: "Сидоров",
                          birthday: 25.years.ago, gender: true, height: 175, weight: 70)
        end
  
        let(:full_name) { "Петр Сидоров" }
        let(:gender) { true }
        let(:start_age) { 20 }
        let(:end_age) { 30 }
        let(:limit) { 1 }
        let(:offset) { 0 }
  
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["patients"].size).to eq(1)
          expect(body["patients"].first["id"]).to eq(patient2.id)
        end
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
          formula: {
            type: :string,
            enum: %w[mifflin harris],
            description: 'Выберите формулу: mifflin – Миффлина–Сан Жеора, harris – Харриса–Бенедикта',
            example: 'mifflin/harris'
          }
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

  path "/api/v1/patients/{patient_id}/bmr_history" do
    get("История расчетов BMR") do
      tags "patients"
      produces "application/json"
      parameter name: :patient_id, in: :path, type: :integer
      parameter name: :limit, in: :query, type: :integer, description: "Лимит на количество записей"
      parameter name: :offset, in: :query, type: :integer, description: "Смещение для пагинации"
  
      let!(:patient) do
        p = Patient.create!(
          first_name: "Иван",
          middle_name: "Иванович",
          last_name: "Петров",
          birthday: Date.new(1990, 1, 1),
          gender: true,
          height: 180,
          weight: 75
        )
        # создаём несколько расчетов
        %w[mifflin harris mifflin].each do |formula|
          p.bmr_calculations.create!(formula: formula, result: p.calculate_bmr(formula))
        end
        p
      end
      let(:patient_id) { patient.id }
  
      response(200, "История расчетов BMR") do
        let(:limit) { 2 }
        let(:offset) { 0 }
  
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["patient_id"]).to eq(patient.id)
          expect(data["bmr_history"].size).to eq(2)
          expect(data["bmr_history"].first["formula"]).to be_in(%w[mifflin harris])
        end
      end
  
      response(404, "Пациент не найден") do
        let(:patient_id) { 0 }
        run_test!
      end
    end
  end

  path "/api/v1/patients/{patient_id}/calculate_bmi" do
    get("Рассчитать BMI через внешний API") do
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

      response(200, "Успешный расчёт BMI") do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["patient_id"]).to eq(patient.id)
          expect(data["bmi"]).to have_key("value")
          expect(data["bmi"]).to have_key("category")
        end
      end

      response(422, "Нет данных для веса/роста") do
        before { patient.update!(weight: nil) }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Weight and height are required to calculate BMI")
        end
      end

      response(404, "Пациент не найден") do
        let(:patient_id) { 0 }
        run_test!
      end
    end
  end
end