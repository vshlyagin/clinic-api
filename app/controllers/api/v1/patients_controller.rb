class Api::V1::PatientsController < ApplicationController
  require "net/http"
  require "json"

  def index
    patients = Patient.all
      .by_full_name(params[:full_name])
      .by_gender(params[:gender])
      .by_age(params[:start_age], params[:end_age])

    patients = patients.limit(params[:limit]) if params[:limit].present?
    patients = patients.offset(params[:offset]) if params[:offset].present?

    render json: { patients: patients }
  end

  def show
    render json: { patient: patient }
  end

  def create
    if patient.valid?
      patient.save!
      patient.doctor_ids = patient_params[:doctor_ids] if patient_params[:doctor_ids]&.any?
      render json: { patient: patient, doctors: patient.doctors }, status: :created
    else
      render json: { errors: patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if patient.valid?
      patient.save!
      patient.doctor_ids = patient_params[:doctor_ids] if patient_params[:doctor_ids]&.any?
      render json: { patient: patient, doctors: patient.doctors }
    else
      render json: { errors: patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    patient.destroy
    head :no_content
  end

  def calculate_bmr
    formula = params[:formula]
    result = patient.calculate_bmr(formula)

    calculation = patient.bmr_calculations.create!(
      formula: formula,
      result: result
    )

    render json: { patient_id: patient.id, formula: formula, result: result }, status: :created
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
  end

  def bmr_history
    history = patient.bmr_calculations.order(created_at: :desc)
    history = history.limit(params[:limit]) if params[:limit].present?
    history = history.offset(params[:offset]) if params[:offset].present?

    render json: { patient_id: patient.id, bmr_history: history }
  end

  def calculate_bmi
    unless patient.weight && patient.height
      return render json: { error: "Weight and height are required to calculate BMI" }, status: :unprocessable_entity
    end
  
    weight = patient.weight.to_f
    height_m = patient.height.to_f / 100
  
    uri = URI.parse("https://bmicalculatorapi.vercel.app/api/bmi/#{weight}/#{height_m}")
  
    begin
      response = Net::HTTP.get_response(uri)
  
      if response.is_a?(Net::HTTPSuccess)
        bmi_result = JSON.parse(response.body)
  
        render json: {
          patient_id: patient.id,
          bmi: {
            value: bmi_result["bmi"],
            category: bmi_result["Category"]
          }
        }
      else
        render json: { error: "Failed to fetch BMI from external API" }, status: :bad_gateway
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end  

  private

  def patient_params
    params.require(:patient).permit(:first_name, :middle_name, :last_name, :birthday, :gender, :height, :weight, doctor_ids: [])
  end

  def patient
    @patient ||= case action_name
                 when "create"
                   Patient.new
                 when "update", "show", "destroy", "calculate_bmr", "bmr_history", "calculate_bmi"
                   Patient.find(params[:id])
                 end
    @patient.assign_attributes(patient_params) if action_name == "create" || action_name == "update"
    @patient
  end
end
