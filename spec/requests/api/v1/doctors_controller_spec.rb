require 'rails_helper'

RSpec.describe Api::V1::DoctorsController, type: :request do
  before(:each) do
    Doctor.delete_all
  end

  let!(:doctor1) { Doctor.create!(first_name: "Иван", middle_name: "Иванович", last_name: "Петров") }
  let!(:doctor2) { Doctor.create!(first_name: "Пётр", middle_name: "Петрович", last_name: "Сидоров") }

  describe "GET /index" do
    it "возвращает всех докторов с лимитом и смещением" do
      get "/api/v1/doctors", params: { limit: 1, offset: 1 }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["doctors"].size).to eq(1)
      expect(body["doctors"].first["first_name"]).to eq(doctor2.first_name)
    end
  end

  describe "CRUD" do
    it "создаёт доктора" do
      post "/api/v1/doctors", params: { doctor: { first_name: "Мария", last_name: "Петрова", middle_name: "Ивановна" } }
      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)["doctor"]
      expect(data["first_name"]).to eq("Мария")
      expect(data["middle_name"]).to eq("Ивановна")
      expect(data["last_name"]).to eq("Петрова")
    end

    it "показывает доктора" do
      get "/api/v1/doctors/#{doctor1.id}"
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)["doctor"]
      expect(data["id"]).to eq(doctor1.id)
    end

    it "обновляет доктора" do
      patch "/api/v1/doctors/#{doctor1.id}", params: { doctor: { first_name: "Алексей" } }
      expect(response).to have_http_status(:ok)
      expect(Doctor.find(doctor1.id).first_name).to eq("Алексей")
    end

    it "удаляет доктора" do
      delete "/api/v1/doctors/#{doctor1.id}"
      expect(response).to have_http_status(:no_content)
      expect(Doctor.find_by(id: doctor1.id)).to be_nil
    end
  end
end
