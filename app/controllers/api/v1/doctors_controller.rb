class Api::V1::DoctorsController < ApplicationController
  def index
    doctors = Doctor.all

    doctors = doctors.limit(params[:limit]) if params[:limit].present?
    doctors = doctors.offset(params[:offset]) if params[:offset].present?

    render json: { doctors: doctors }
  end

  def show
    render json: { doctor: doctor }
  end

  def create
    if doctor.valid?
      doctor.save!
      render json: { doctor: doctor }, status: :created
    else
      render json: { errors: doctor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if doctor.valid?
      doctor.save!
      render json: { doctor: doctor }
    else
      render json: { errors: doctor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    doctor.destroy
    head :no_content
  end

  private

  def doctor_params
    params.require(:doctor).permit(:first_name, :middle_name, :last_name)
  end

  def doctor
    @doctor ||= case action_name
                when "create"
                  Doctor.new
                when "update", "show", "destroy"
                  Doctor.find(params[:id])
                end
    @doctor.assign_attributes(doctor_params) if action_name.in?(%w[create update])
    @doctor
  end
end
