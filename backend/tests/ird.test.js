const { calculateIrdScore, getIrdCategory, calculateIrd } = require('../src/utils/ird');

describe('IRD Calculation', () => {
  it('should calculate IRD score for male (pria)', () => {
    const result = calculateIrd({
      bloodSugar: 180, systolic: 130, diastolic: 85,
      cholesterol: 220, uricAcid: 6.5, height: 170, weight: 75, gender: 'pria',
    });
    expect(result.irdScore).toBeDefined();
    expect(result.irdCategory).toBeDefined();
    expect(['Rendah', 'Sedang', 'Berat']).toContain(result.irdCategory);
  });

  it('should calculate IRD score for female (wanita)', () => {
    const result = calculateIrd({
      bloodSugar: 120, systolic: 110, diastolic: 70,
      cholesterol: 180, uricAcid: 4.5, height: 160, weight: 55, gender: 'wanita',
    });
    expect(result.irdScore).toBeLessThan(1.0);
    expect(result.irdCategory).toBe('Rendah');
  });

  it('should categorize IRD correctly', () => {
    expect(getIrdCategory(0.5)).toBe('Rendah');
    expect(getIrdCategory(0.75)).toBe('Sedang');
    expect(getIrdCategory(0.85)).toBe('Sedang');
    expect(getIrdCategory(1.0)).toBe('Sedang');
    expect(getIrdCategory(1.2)).toBe('Berat');
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
