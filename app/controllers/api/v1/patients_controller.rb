class Api::V1::PatientsController < ApplicationController
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
      render json: { patient: patient }, status: :created
    else
      render json: { errors: patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if patient.valid?
      patient.save!
      render json: { patient: patient }
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

  private

  def patient_params
    params.require(:patient).permit(:first_name, :middle_name, :last_name, :birthday, :gender, :height, :weight)
  end

  def patient
    @patient ||= case action_name
                 when "create"
                   Patient.new
                 when "update", "show", "destroy", "calculate_bmr"
                   Patient.find(params[:id])
                 end
    @patient.assign_attributes(patient_params) if action_name == "create" || action_name == "update"
    @patient
  end
end
