#!/usr/bin/env python3
import math
from datetime import datetime

def calculate_moon_phase(date):
    """Вычисляет фазу луны для заданной даты"""
    known_new_moon = datetime(2000, 1, 6, 18, 14)
    synodic_month = 29.530588853
    days_since = (date - known_new_moon).total_seconds() / (24 * 3600)
    cycles = days_since / synodic_month
    phase = cycles - math.floor(cycles)
    return phase

def get_moon_bw(phase):
    """Возвращает черно-белые символы для фазы луны"""
    if phase < 0.0625:
        return "●"      # Новолуние
    elif phase < 0.1875:
        return "◐"      # Молодая луна
    elif phase < 0.3125:
        return "◑"      # Первая четверть
    elif phase < 0.4375:
        return "◒"      # Прибывающая луна
    elif phase < 0.5625:
        return "○"      # Полнолуние
    elif phase < 0.6875:
        return "◓"      # Убывающая луна
    elif phase < 0.8125:
        return "◒"      # Последняя четверть
    elif phase < 0.9375:
        return "◑"      # Старая луна
    else:
        return "●"      # Новолуние

def calculate_illumination(phase):
    """Вычисляет процент освещенности"""
    illumination = (1 - math.cos(2 * math.pi * phase)) / 2
    return illumination * 100

def get_trend_arrow(phase):
    """Возвращает стрелку направления изменения"""
    if phase < 0.03 or phase > 0.97:  # Новолуние
        return "↗"  # Начинает расти
    elif 0.47 < phase < 0.53:  # Полнолуние
        return "↘"  # Начинает убывать
    elif phase < 0.5:
        return "↗"  # Растет
    else:
        return "↘"  # Убывает

if __name__ == "__main__":
    today = datetime.now()
    phase = calculate_moon_phase(today)
    illumination = calculate_illumination(phase)
    trend = get_trend_arrow(phase)
    
    print(f"{get_moon_bw(phase)} {illumination:.0f}%{trend}")
