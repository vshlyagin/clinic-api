require 'swagger_helper'

RSpec.describe 'api/v1/doctors', type: :request do

  path '/api/v1/doctors' do
    get("Список докторов") do
      tags "doctors"
      produces "application/json"
      parameter name: :limit, in: :query, type: :integer, description: "Лимит на количество записей"
      parameter name: :offset, in: :query, type: :integer, description: "Смещение для пагинации"
  
      response(200, 'Список врачей') do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {"$ref" => "#/components/schemas/Doctor"}
            }
          }
  
        let!(:doctor1) { Doctor.create!(first_name: "Иван", middle_name: "Иванович", last_name: "Петров") }
        let!(:doctor2) { Doctor.create!(first_name: "Петр", middle_name: "Петрович", last_name: "Сидоров") }
        let(:limit) { 1 }
        let(:offset) { 1 }
  
        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["data"].size).to eq(1)
          # проверяем, что вернулся именно второй доктор
          expect(body["data"].first["id"]).to eq(doctor2.id)
        end
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
