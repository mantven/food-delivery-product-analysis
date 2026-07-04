from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt


def find_base_dir() -> Path:
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
        print(f"Файл не найден, график будет пропущен: {path}")
        return None

    df = pd.read_csv(path, sep=None, engine="python", encoding="utf-8-sig")
    return clean_dataframe(df)


def save_chart(filename: str) -> None:
    path = IMAGES_DIR / filename
    plt.tight_layout()
    plt.savefig(path, dpi=200, bbox_inches="tight")
    plt.close()
    print(f"Сохранено: {path}")


def add_bar_labels(bars, value_format="{:.0f}") -> None:
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


def plot_delivery_time_distribution() -> None:
    df = read_export("delivery_time_distribution.csv")
    if df is None:
        return

    order = ["0-15 min", "16-30 min", "31-45 min", "46-60 min", "60+ min"]
    df["delivery_time_group"] = pd.Categorical(
        df["delivery_time_group"],
        categories=order,
        ordered=True,
    )
    df = df.sort_values("delivery_time_group")

    plt.figure(figsize=(10, 6))
    bars = plt.bar(
        df["delivery_time_group"].astype(str),
        df["orders_count"],
    )

    add_bar_labels(bars)

    plt.title("Distribution of delivery time")
    plt.xlabel("Delivery time group")
    plt.ylabel("Orders count")
    plt.grid(axis="y", alpha=0.3)

    save_chart("delivery_time_distribution.png")


def plot_orders_by_day() -> None:
    df = read_export("orders_by_day.csv")
    if df is None:
        return

    df["order_date"] = pd.to_datetime(df["order_date"])
    df = df.sort_values("order_date")

    plt.figure(figsize=(12, 6))

    plt.plot(
        df["order_date"],
        df["successful_orders"],
        marker="o",
        label="Successful orders",
    )

    if "active_users" in df.columns:
        plt.plot(
            df["order_date"],
            df["active_users"],
            marker="o",
            label="Active users",
        )

    plt.title("Successful orders and active users by day")
    plt.xlabel("Date")
    plt.ylabel("Count")
    plt.xticks(rotation=45)
    plt.grid(axis="y", alpha=0.3)
    plt.legend()

    save_chart("orders_by_day.png")


def plot_deliveries_by_hour() -> None:
    df = read_export("deliveries_by_hour.csv")
    if df is None:
        return

    df["delivery_hour_num"] = pd.to_numeric(df["delivery_hour"], errors="coerce")
    df = df.sort_values("delivery_hour_num")
    df["delivery_hour_label"] = df["delivery_hour_num"].astype(int).map(
        lambda x: f"{x:02d}:00"
    )

    plt.figure(figsize=(12, 6))
    bars = plt.bar(
        df["delivery_hour_label"],
        df["delivered_orders"],
    )

    plt.title("Deliveries by hour")
    plt.xlabel("Hour")
    plt.ylabel("Delivered orders")
    plt.xticks(rotation=45)
    plt.grid(axis="y", alpha=0.3)

    save_chart("deliveries_by_hour.png")


def plot_avg_delivery_time_by_hour() -> None:
    df = read_export("deliveries_by_hour.csv")
    if df is None:
        return

    if "avg_delivery_time_minutes" not in df.columns:
        print("В deliveries_by_hour.csv нет колонки avg_delivery_time_minutes")
        return

    df["delivery_hour_num"] = pd.to_numeric(df["delivery_hour"], errors="coerce")
    df = df.sort_values("delivery_hour_num")
    df["delivery_hour_label"] = df["delivery_hour_num"].astype(int).map(
        lambda x: f"{x:02d}:00"
    )

    plt.figure(figsize=(12, 6))
    plt.plot(
        df["delivery_hour_label"],
        df["avg_delivery_time_minutes"],
        marker="o",
    )

    plt.title("Average delivery time by hour")
    plt.xlabel("Hour")
    plt.ylabel("Average delivery time, minutes")
    plt.xticks(rotation=45)
    plt.grid(axis="y", alpha=0.3)

    save_chart("avg_delivery_time_by_hour.png")


def plot_retention_curve() -> None:
    df = read_export("retention_curve.csv")
    if df is None:
        return

    df = df.sort_values("day_number")

    plt.figure(figsize=(10, 6))
    plt.plot(
        df["day_number"],
        df["retention_rate_percent"],
        marker="o",
    )

    plt.title("Retention after first successful order")
    plt.xlabel("Day after first order")
    plt.ylabel("Retention rate, %")
    plt.ylim(bottom=0)
    plt.grid(axis="y", alpha=0.3)

    save_chart("retention_curve.png")


def plot_users_by_orders_count() -> None:
    df = read_export("users_by_orders_count.csv")
    if df is None:
        return

    df = df.sort_values("orders_count")

    plt.figure(figsize=(12, 6))
    bars = plt.bar(
        df["orders_count"].astype(str),
        df["users_count"],
    )

    add_bar_labels(bars)

    plt.title("Users by number of successful orders")
    plt.xlabel("Successful orders count")
    plt.ylabel("Users count")
    plt.grid(axis="y", alpha=0.3)

    save_chart("users_by_orders_count.png")


def plot_top_couriers() -> None:
    df = read_export("top_couriers.csv")
    if df is None:
        return

    df = df.sort_values("delivered_orders", ascending=True)

    plt.figure(figsize=(10, 6))
    bars = plt.barh(
        df["courier_id"].astype(str),
        df["delivered_orders"],
    )

    for bar in bars:
        width = bar.get_width()
        plt.text(
            width,
            bar.get_y() + bar.get_height() / 2,
            f"{width:.0f}",
            va="center",
            fontsize=9,
        )

    plt.title("Top couriers by delivered orders")
    plt.xlabel("Delivered orders")
    plt.ylabel("Courier ID")
    plt.grid(axis="x", alpha=0.3)

    save_chart("top_couriers.png")


def main() -> None:
    print(f"Корневая папка проекта: {BASE_DIR}")
    print(f"Папка с CSV: {EXPORTS_DIR}")
    print(f"Папка для картинок: {IMAGES_DIR}")

    plot_delivery_time_distribution()
    plot_orders_by_day()
    plot_deliveries_by_hour()
    plot_avg_delivery_time_by_hour()
    plot_retention_curve()
    plot_users_by_orders_count()
    plot_top_couriers()

    print("Готово. Все доступные графики сохранены в папку images.")


if __name__ == "__main__":
    main()
