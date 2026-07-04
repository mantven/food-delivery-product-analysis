from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt


def find_base_dir() -> Path:
    """
    Ищет корневую папку проекта.
    Скрипт можно запускать как из корня проекта, так и из папки scripts.
    """
    script_dir = Path(__file__).resolve().parent

    candidates = [
        Path.cwd(),
        script_dir,
        script_dir.parent,
    ]

    for candidate in candidates:
        if (candidate / "exports").exists():
            return candidate

    return Path.cwd()


BASE_DIR = find_base_dir()
EXPORTS_DIR = BASE_DIR / "exports"
IMAGES_DIR = BASE_DIR / "images"

IMAGES_DIR.mkdir(exist_ok=True)


def clean_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """
    Чистит названия колонок и преобразует числа.
    Нужно, если DBeaver выгрузил десятичные числа через запятую.
    """
    df.columns = [col.strip().replace('"', "") for col in df.columns]

    for col in df.columns:
        if df[col].dtype == "object":
            s = df[col].astype(str).str.strip()

            numeric_candidate = (
                s.str.replace("\u00a0", "", regex=False)
                .str.replace(" ", "", regex=False)
                .str.replace(",", ".", regex=False)
            )

            converted = pd.to_numeric(numeric_candidate, errors="coerce")
            non_empty_count = s.ne("").sum()

            if non_empty_count > 0 and converted.notna().sum() == non_empty_count:
                df[col] = converted
            else:
                df[col] = s

    return df


def read_export(filename: str) -> pd.DataFrame | None:
    path = EXPORTS_DIR / filename

    if not path.exists():
        print(f"Файл не найден, график пропущен: {path}")
        return None

    df = pd.read_csv(path, sep=None, engine="python", encoding="utf-8-sig")
    return clean_dataframe(df)


def save_chart(filename: str) -> None:
    path = IMAGES_DIR / filename
    plt.tight_layout()
    plt.savefig(path, dpi=200, bbox_inches="tight")
    plt.close()
    print(f"Сохранено: {path}")


def add_bar_labels(bars, value_format="{:.2f}") -> None:
    for bar in bars:
        height = bar.get_height()
        plt.text(
            bar.get_x() + bar.get_width() / 2,
            height,
            value_format.format(height),
            ha="center",
            va="bottom",
            fontsize=9,
        )


def order_age_groups(df: pd.DataFrame) -> pd.DataFrame:
    age_order = ["under 18", "18-24", "25-34", "35-44", "45+"]
    df["age_group"] = pd.Categorical(
        df["age_group"],
        categories=age_order,
        ordered=True,
    )
    return df.sort_values("age_group")


def plot_avg_delivery_time_by_sex() -> None:
    df = read_export("avg_delivery_time_by_sex.csv")
    if df is None:
        return

    df = df.sort_values("avg_delivery_time_minutes")

    plt.figure(figsize=(8, 5))
    bars = plt.bar(
        df["sex"],
        df["avg_delivery_time_minutes"],
    )

    add_bar_labels(bars, "{:.2f}")

    plt.title("Average delivery time by courier sex")
    plt.xlabel("Courier sex")
    plt.ylabel("Average delivery time, minutes")
    plt.ylim(
        df["avg_delivery_time_minutes"].min() - 0.1,
        df["avg_delivery_time_minutes"].max() + 0.1,
    )
    plt.grid(axis="y", alpha=0.3)

    save_chart("avg_delivery_time_by_sex.png")


def plot_courier_workload_by_sex() -> None:
    df = read_export("courier_workload_by_sex.csv")
    if df is None:
        return

    df = df.sort_values("avg_orders_per_courier", ascending=False)

    plt.figure(figsize=(8, 5))
    bars = plt.bar(
        df["sex"],
        df["avg_orders_per_courier"],
    )

    add_bar_labels(bars, "{:.2f}")

    plt.title("Average orders per courier by sex")
    plt.xlabel("Courier sex")
    plt.ylabel("Average orders per courier")
    plt.grid(axis="y", alpha=0.3)

    save_chart("courier_workload_by_sex.png")


def plot_couriers_by_age_group() -> None:
    df = read_export("couriers_by_age_group.csv")
    if df is None:
        return

    print("Колонки в couriers_by_age_group.csv:", list(df.columns))

    df = order_age_groups(df)

    if "couriers_count" in df.columns:
        count_column = "couriers_count"
    elif "active_couriers" in df.columns:
        count_column = "active_couriers"
    else:
        print("Не найдена колонка couriers_count или active_couriers")
        print("Доступные колонки:", list(df.columns))
        return

    plt.figure(figsize=(9, 5))
    bars = plt.bar(
        df["age_group"].astype(str),
        df[count_column],
    )

    add_bar_labels(bars, "{:.0f}")

    plt.title("Couriers by age group")
    plt.xlabel("Age group")
    plt.ylabel("Couriers count")
    plt.grid(axis="y", alpha=0.3)

    save_chart("couriers_by_age_group.png")


def plot_avg_delivery_time_by_age_group() -> None:
    df = read_export("avg_delivery_time_by_age_group.csv")
    if df is None:
        return

    df = order_age_groups(df)

    plt.figure(figsize=(9, 5))
    bars = plt.bar(
        df["age_group"].astype(str),
        df["avg_delivery_time_minutes"],
    )

    add_bar_labels(bars, "{:.2f}")

    plt.title("Average delivery time by courier age group")
    plt.xlabel("Age group")
    plt.ylabel("Average delivery time, minutes")
    plt.ylim(
        df["avg_delivery_time_minutes"].min() - 0.1,
        df["avg_delivery_time_minutes"].max() + 0.1,
    )
    plt.grid(axis="y", alpha=0.3)

    save_chart("avg_delivery_time_by_age_group.png")


def plot_avg_delivery_time_by_sex_age_group() -> None:
    df = read_export("avg_delivery_time_by_sex_age_group.csv")
    if df is None:
        return

    df = order_age_groups(df)

    pivot = df.pivot(
        index="age_group",
        columns="sex",
        values="avg_delivery_time_minutes",
    )

    ax = pivot.plot(
        kind="bar",
        figsize=(10, 6),
    )

    plt.title("Average delivery time by sex and age group")
    plt.xlabel("Age group")
    plt.ylabel("Average delivery time, minutes")
    plt.xticks(rotation=0)
    plt.grid(axis="y", alpha=0.3)
    plt.legend(title="Courier sex")

    min_value = df["avg_delivery_time_minutes"].min()
    max_value = df["avg_delivery_time_minutes"].max()
    plt.ylim(min_value - 0.1, max_value + 0.1)

    for container in ax.containers:
        ax.bar_label(container, fmt="%.2f", fontsize=8, padding=3)

    save_chart("avg_delivery_time_by_sex_age_group.png")


def main() -> None:
    print(f"Корневая папка проекта: {BASE_DIR}")
    print(f"Папка с CSV: {EXPORTS_DIR}")
    print(f"Папка для PNG: {IMAGES_DIR}")

    plot_avg_delivery_time_by_sex()
    plot_courier_workload_by_sex()
    plot_couriers_by_age_group()
    plot_avg_delivery_time_by_age_group()
    plot_avg_delivery_time_by_sex_age_group()

    print("Готово. Все графики сохранены в папку images.")


if __name__ == "__main__":
    main()