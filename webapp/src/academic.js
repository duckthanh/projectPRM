export function currentAcademicPeriod() {
  const now = new Date();
  const startYear = now.getMonth() + 1 >= 8 ? now.getFullYear() : now.getFullYear() - 1;
  return {
    academicYear: `${startYear}-${startYear + 1}`,
    semester: now.getMonth() + 1 >= 8 ? 1 : 2,
  };
}

export function academicYearOptions() {
  const { academicYear } = currentAcademicPeriod();
  const start = Number(academicYear.slice(0, 4));
  return [start - 1, start, start + 1].map((year) => `${year}-${year + 1}`);
}
