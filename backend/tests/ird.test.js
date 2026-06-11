const { calculateIrdScore, getIrdCategory, calculateIrd } = require('../src/utils/ird');

describe('IRD Calculation', () => {
  it('should calculate IRD score for male (pria)', () => {
    const result = calculateIrd({
      bloodSugar: 180, systolic: 130, diastolic: 85,
      cholesterol: 220, uricAcid: 6.5, height: 170, weight: 75, gender: 'pria',
    });
    expect(result.irdScore).toBeDefined();
    expect(result.irdCategory).toBeDefined();
    expect(['normal', 'attention', 'high']).toContain(result.irdCategory);
  });

  it('should calculate IRD score for female (wanita)', () => {
    const result = calculateIrd({
      bloodSugar: 120, systolic: 110, diastolic: 70,
      cholesterol: 180, uricAcid: 4.5, height: 160, weight: 55, gender: 'wanita',
    });
    expect(result.irdScore).toBeLessThan(1.0);
    expect(result.irdCategory).toBe('normal');
  });

  it('should categorize IRD correctly', () => {
    expect(getIrdCategory(0.5)).toBe('normal');
    expect(getIrdCategory(0.75)).toBe('attention');
    expect(getIrdCategory(0.85)).toBe('attention');
    expect(getIrdCategory(1.0)).toBe('attention');
    expect(getIrdCategory(1.2)).toBe('high');
  });

  it('should use correct AU denominator for gender', () => {
    const male = calculateIrd({
      bloodSugar: 100, systolic: 120, diastolic: 80,
      cholesterol: 200, uricAcid: 7.0, height: 170, weight: 70, gender: 'pria',
    });
    const female = calculateIrd({
      bloodSugar: 100, systolic: 120, diastolic: 80,
      cholesterol: 200, uricAcid: 7.0, height: 170, weight: 70, gender: 'wanita',
    });
    // Same uric acid should produce lower score for male (denominator 7.0 > 6.0)
    expect(male.irdScore).toBeLessThan(female.irdScore);
  });

  it('should treat every male spelling the same (Pria/male/laki-laki)', () => {
    const base = {
      bloodSugar: 100, systolic: 120, diastolic: 80,
      cholesterol: 200, uricAcid: 7.0, height: 170, weight: 70,
    };
    const pria = calculateIrd({ ...base, gender: 'Pria' });
    for (const gender of ['pria', 'male', 'laki-laki', 'MALE']) {
      expect(calculateIrd({ ...base, gender }).irdScore).toBe(pria.irdScore);
    }
    // and every non-male spelling gets the 6.0 denominator
    const wanita = calculateIrd({ ...base, gender: 'Wanita' });
    expect(wanita.irdScore).toBeGreaterThan(pria.irdScore);
    expect(calculateIrd({ ...base, gender: 'female' }).irdScore).toBe(wanita.irdScore);
  });

  it('should round score to 2 decimal places', () => {
    const result = calculateIrd({
      bloodSugar: 180, systolic: 130, diastolic: 85,
      cholesterol: 220, uricAcid: 6.5, height: 170, weight: 75, gender: 'pria',
    });
    const decimalStr = result.irdScore.toString();
    const decimals = decimalStr.includes('.') ? decimalStr.split('.')[1].length : 0;
    expect(decimals).toBeLessThanOrEqual(2);
  });
});
