const calculateIrdScore = ({ bloodSugar, systolic, diastolic, cholesterol, uricAcid, height, weight, gender }) => {
  const bmi = weight / ((height / 100) ** 2);
  const auDenominator = gender.toLowerCase() === 'pria' ? 7.0 : 6.0;

  const gdsComponent = 0.3 * (bloodSugar / 200);
  const bpComponent = 0.2 * ((systolic / 140 + diastolic / 90) / 2);
  const kolComponent = 0.2 * (cholesterol / 240);
  const auComponent = 0.15 * (uricAcid / auDenominator);
  const bmiComponent = 0.15 * (bmi / 25);

  return gdsComponent + bpComponent + kolComponent + auComponent + bmiComponent;
};

const getIrdCategory = (irdScore) => {
  if (irdScore < 0.75) return 'normal';
  if (irdScore <= 1.0) return 'attention';
  return 'high';
};

const calculateIrd = (params) => {
  const irdScore = calculateIrdScore(params);
  const irdCategory = getIrdCategory(irdScore);
  return { irdScore: Math.round(irdScore * 100) / 100, irdCategory };
};

module.exports = { calculateIrdScore, getIrdCategory, calculateIrd };
