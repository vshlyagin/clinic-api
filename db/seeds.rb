doctor = Doctor.create!(
  first_name: "Алексей",
  middle_name: "Иванович",
  last_name: "Смирнов"
)

patient1 = Patient.create!(
  first_name: "Мария",
  middle_name: "Сергеевна",
  last_name: "Кузнецова",
  birthday: Date.new(1985, 3, 15),
  gender: false, # женский
  height: 165,
  weight: 60
)

doctor.patients << patient1

patient2 = Patient.create!(
  first_name: "Иван",
  middle_name: "Петрович",
  last_name: "Орлов",
  birthday: Date.new(1992, 7, 22),
  gender: true, # мужской
  height: 180,
  weight: 85
)
