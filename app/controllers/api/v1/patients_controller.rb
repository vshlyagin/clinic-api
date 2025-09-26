class Api::V1::PatientsController < ApplicationController
  def index
    patients = Patient.all
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

  private

  def patient_params
    params.require(:patient).permit(:first_name, :middle_name, :last_name, :birthday, :gender, :height, :weight)
  end

  def patient
    @patient ||= case action_name
                 when "create"
                   Patient.new
                 when "update", "show", "destroy"
                   Patient.find(params[:id])
                 end
    @patient.assign_attributes(patient_params) if action_name == "create" || action_name == "update"
    @patient
  end
end
