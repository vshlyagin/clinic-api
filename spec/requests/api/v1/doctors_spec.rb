require 'swagger_helper'

RSpec.describe 'api/v1/doctors', type: :request do

  path '/api/v1/doctors' do

    get("Список докторов") do
      tags "doctors"
      produces "application/json"

      response(200, 'Список врачей') do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {"$ref" => "#/components/schemas/Doctor"}
            }
          }

        let!(:doctor) do
          Doctor.create!(
            first_name: "Иван",
            middle_name: "Иванович",
            last_name: "Петров"
          )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          data = body["data"].first
          expect(data["id"]).to eq(doctor.id)
          expect(data["first_name"]).to eq("Иван")
          expect(data["middle_name"]).to eq("Иванович")
          expect(data["last_name"]).to eq("Петров")
        end
      end
    end

    post("Создать доктора") do
      tags "doctors"
      consumes "application/json"
      produces "application/json"
      parameter name: :doctor, in: :body, schema: {"$ref" => "#/components/schemas/Doctor"}

      response(201, 'Врач создан') do
        let(:doctor) do
          {
            first_name: "Петр",
            middle_name: "Петрович",
            last_name: "Сидоров"
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

      response(422, 'Некорректные данные') do
        let(:doctor) { { first_name: "" } }
        run_test!
      end
    end
  end

  path '/api/v1/doctors/{doctor_id}' do
    parameter name: :doctor_id, in: :path, type: :integer

    get("Показать доктора") do
      tags "doctors"
      produces "application/json"

      let!(:doctor) do
        Doctor.create!(
          first_name: "Иван",
          middle_name: "Иванович",
          last_name: "Петров"
        )
      end
      let(:doctor_id) { doctor.id }

      response(200, 'Врач найден') do
        run_test! do |response|
          body = JSON.parse(response.body)
          data = body["data"]
          expect(data["id"]).to eq(doctor.id)
        end
      end

      response(404, 'Врач не найден') do
        let(:doctor_id) { 0 }
        run_test!
      end
    end

    patch("Обновить доктора") do
      tags "doctors"
      consumes "application/json"
      produces "application/json"
      parameter name: :doctor, in: :body, schema: {"$ref" => "#/components/schemas/Doctor"}

      let!(:doctor) do
        Doctor.create!(
          first_name: "Иван",
          middle_name: "Иванович",
          last_name: "Петров"
        )
      end
      let(:doctor_id) { doctor.id }
      let(:doctor) { { first_name: "Петр" } }

      response(200, 'Врач обновлён') do
        run_test! do
          expect(Doctor.find(doctor_id).first_name).to eq("Петр")
        end
      end
    end

    delete("Удалить доктора") do
      tags "doctors"
      produces "application/json"

      let!(:doctor) do
        Doctor.create!(
          first_name: "Иван",
          middle_name: "Иванович",
          last_name: "Петров"
        )
      end
      let(:doctor_id) { doctor.id }

      response(204, 'Врач удалён') do
        run_test! do
          expect(Doctor.find_by(id: doctor_id)).to be_nil
        end
      end

      response(404, 'Врач не найден') do
        let(:doctor_id) { 0 }
        run_test!
      end
    end
  end
end
