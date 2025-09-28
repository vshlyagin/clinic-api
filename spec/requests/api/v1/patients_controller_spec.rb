require 'rails_helper'
require 'webmock/rspec'


RSpec.describe Api::V1::PatientsController, type: :request do
  let!(:doctor) { Doctor.create!(first_name: "Иван", middle_name: "Иванович", last_name: "Петров") }
  let!(:patient1) do
    Patient.create!(
      first_name: "Анна", middle_name: "Ивановна", last_name: "Смирнова",
      birthday: 20.years.ago, gender: true, height: 170, weight: 65
    )
  end
  let!(:patient2) do
    p = Patient.create!(
      first_name: "Пётр", middle_name: "Петрович", last_name: "Иванов",
      birthday: 30.years.ago, gender: false, height: 180, weight: 80
    )
    doctor.patients << p
    p
  end

  before(:all) do
    Patient.delete_all
    Doctor.delete_all
  end

  describe "GET /index" do
    it "возвращает всех пациентов с фильтром и пагинацией" do
      get "/api/v1/patients", params: { limit: 1, offset: 1 }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["patients"].size).to eq(1)
      expect(body["patients"].first["first_name"]).to eq(patient2.first_name)
    end
  end

  describe "CRUD" do
    it "создаёт пациента" do
      post "/api/v1/patients", params: { patient: { first_name: "Мария", last_name: "Петрова", gender: true } }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["patient"]["first_name"]).to eq("Мария")
    end

    it "показывает пациента" do
      get "/api/v1/patients/#{patient1.id}"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["patient"]["id"]).to eq(patient1.id)
    end

    it "обновляет пациента" do
      patch "/api/v1/patients/#{patient1.id}", params: { patient: { weight: 70 } }
      expect(response).to have_http_status(:ok)
      expect(Patient.find(patient1.id).weight).to eq(70)
    end

    it "удаляет пациента" do
      delete "/api/v1/patients/#{patient1.id}"
      expect(response).to have_http_status(:no_content)
      expect(Patient.find_by(id: patient1.id)).to be_nil
    end
  end

  describe "BMR calculations" do
    it "рассчитывает BMR" do
      post "/api/v1/patients/#{patient2.id}/calculate_bmr", params: { formula: "mifflin" }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["formula"]).to eq("mifflin")
      expect(body["result"]).to be_a(Float).or be_a(Integer)
    end

    it "возвращает историю BMR с пагинацией" do
      %w[mifflin harris].each { |f| patient2.bmr_calculations.create!(formula: f, result: patient2.calculate_bmr(f)) }
      get "/api/v1/patients/#{patient2.id}/bmr_history", params: { limit: 1, offset: 1 }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["bmr_history"].size).to eq(1)
    end
  end

  describe "GET /calculate_bmi" do
    before do
      bmi_response = {
        "Category" => "Normal weight",
        "bmi" => 22.5,
        "height" => 1.7,
        "weight" => 65
      }.to_json

      stub_request(:get, "https://bmicalculatorapi.vercel.app/api/bmi/65.0/1.7")
        .to_return(status: 200, body: bmi_response, headers: { 'Content-Type' => 'application/json' })
    end

    it "возвращает корректный BMI" do
      get "/api/v1/patients/#{patient1.id}/calculate_bmi"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body["patient_id"]).to eq(patient1.id)
      expect(body["bmi"]["value"]).to eq(22.5)
      expect(body["bmi"]["category"]).to eq("Normal weight")
    end

    it "обрабатывает отсутствие веса или роста" do
      patient1.update(weight: nil)
      get "/api/v1/patients/#{patient1.id}/calculate_bmi"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Weight and height are required to calculate BMI")
    end

    it "обрабатывает ошибки внешнего API" do
      stub_request(:get, "https://bmicalculatorapi.vercel.app/api/bmi/65.0/1.7")
        .to_return(status: 500)

      get "/api/v1/patients/#{patient1.id}/calculate_bmi"

      expect(response).to have_http_status(:bad_gateway)
      expect(JSON.parse(response.body)["error"]).to eq("Failed to fetch BMI from external API")
    end
  end
end
