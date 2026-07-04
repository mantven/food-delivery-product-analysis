from pathlib import Path

import pandas as pd
import scipy.stats as stats
import statsmodels.api as sm
import statsmodels.formula.api as smf


BASE_DIR = Path.cwd()
EXPORTS_DIR = BASE_DIR / "exports"

df = pd.read_csv(EXPORTS_DIR / "courier_level_profile_filtered.csv")

df.columns = [col.strip() for col in df.columns]

for col in ["delivered_orders", "avg_delivery_time_minutes"]:
    df[col] = (
        df[col]
        .astype(str)
        .str.replace(",", ".", regex=False)
        .astype(float)
    )

print("Размер данных:")
print(df.shape)
print()

print("Первые строки:")
print(df.head())
print()


# Описательная статистика по полу

print("Среднее время доставки по полу:")
sex_stats = (
    df.groupby("sex")
    .agg(
        couriers_count=("courier_id", "count"),
        avg_delivery_time=("avg_delivery_time_minutes", "mean"),
        std_delivery_time=("avg_delivery_time_minutes", "std"),
        median_delivery_time=("avg_delivery_time_minutes", "median"),
        avg_orders=("delivered_orders", "mean"),
    )
    .round(4)
)

print(sex_stats)
print()


# Welch t-test для сравнения пола

female = df.loc[df["sex"] == "female", "avg_delivery_time_minutes"]
male = df.loc[df["sex"] == "male", "avg_delivery_time_minutes"]

t_stat, p_value = stats.ttest_ind(female, male, equal_var=False)

diff_minutes = female.mean() - male.mean()
diff_seconds = diff_minutes * 60


def cohens_d(x, y):
    nx = len(x)
    ny = len(y)
    pooled_std = (((nx - 1) * x.var(ddof=1) + (ny - 1) * y.var(ddof=1)) / (nx + ny - 2)) ** 0.5
    return (x.mean() - y.mean()) / pooled_std


d = cohens_d(female, male)

print("Welch t-test по полу:")
print(f"Среднее female: {female.mean():.4f} мин.")
print(f"Среднее male:   {male.mean():.4f} мин.")
print(f"Разница:        {diff_minutes:.4f} мин. = {diff_seconds:.2f} сек.")
print(f"t-statistic:    {t_stat:.4f}")
print(f"p-value:        {p_value:.6f}")
print(f"Cohen's d:      {d:.4f}")
print()


# ANOVA по возрастным группам

print("Среднее время доставки по возрастным группам:")
age_stats = (
    df.groupby("age_group")
    .agg(
        couriers_count=("courier_id", "count"),
        avg_delivery_time=("avg_delivery_time_minutes", "mean"),
        std_delivery_time=("avg_delivery_time_minutes", "std"),
        avg_orders=("delivered_orders", "mean"),
    )
    .round(4)
)

print(age_stats)
print()

groups = [
    group["avg_delivery_time_minutes"].values
    for _, group in df.groupby("age_group")
]

f_stat, age_p_value = stats.f_oneway(*groups)

print("One-way ANOVA по возрастным группам:")
print(f"F-statistic: {f_stat:.4f}")
print(f"p-value:     {age_p_value:.6f}")
print()

grand_mean = df["avg_delivery_time_minutes"].mean()

ss_between = sum(
    len(group) * (group["avg_delivery_time_minutes"].mean() - grand_mean) ** 2
    for _, group in df.groupby("age_group")
)

ss_total = sum((df["avg_delivery_time_minutes"] - grand_mean) ** 2)

eta_squared = ss_between / ss_total

print("Размер эффекта возраста:")
print(f"Eta squared: {eta_squared:.6f}")
print()


# --------------------------------------------------
# 5. Двухфакторная ANOVA: пол + возраст + взаимодействие
# --------------------------------------------------

model = smf.ols(
    "avg_delivery_time_minutes ~ C(sex) + C(age_group) + C(sex):C(age_group)",
    data=df
).fit()

anova_table = sm.stats.anova_lm(model, typ=2)

print("Two-way ANOVA: sex + age_group + interaction")
print(anova_table)
print()


# --------------------------------------------------
# 6. Практическая интерпретация
# --------------------------------------------------

print("Интерпретация:")
print("- Если p-value < 0.05, различие статистически значимо.")
print("- Если Cohen's d < 0.2, эффект считается очень слабым.")
print("- Если eta squared < 0.01, эффект возраста практически ничтожный.")
print("- Для бизнеса важнее разница в минутах/секундах, а не только p-value.")
