#!/usr/bin/env python3
import math
import subprocess
import time
from datetime import datetime, timedelta

def calculate_sunrise_sunset(latitude, longitude, date, timezone_offset=0):
    """
    Вычисляет время восхода и заката солнца
    
    Args:
        latitude: широта в градусах (-90 до 90)
        longitude: долгота в градусах (-180 до 180)
        date: дата в формате datetime
        timezone_offset: смещение часового пояса от UTC в часах
    
    Returns:
        tuple: (время восхода, время заката) в формате datetime
    """
    
    # Преобразуем в радианы
    lat_rad = math.radians(latitude)
    
    # Номер дня в году
    day_of_year = date.timetuple().tm_yday
    
    # Склонение солнца
    declination = math.radians(23.45) * math.sin(math.radians(360 * (284 + day_of_year) / 365))
    
    # Часовой угол восхода/заката
    try:
        hour_angle = math.acos(-math.tan(lat_rad) * math.tan(declination))
    except ValueError:
        # Полярный день или полярная ночь
        if latitude * declination > 0:
            return None, None  # Полярный день - солнце не заходит
        else:
            return None, None  # Полярная ночь - солнце не восходит
    
    # Уравнение времени (поправка на эллиптичность орбиты)
    B = math.radians(360 * (day_of_year - 81) / 365)
    equation_of_time = 9.87 * math.sin(2 * B) - 7.53 * math.cos(B) - 1.5 * math.sin(B)
    
    # Время восхода и заката в часах от полудня
    time_correction = 4 * (longitude - 15 * timezone_offset) + equation_of_time
    
    sunrise_time = 12 - math.degrees(hour_angle) / 15 - time_correction / 60
    sunset_time = 12 + math.degrees(hour_angle) / 15 - time_correction / 60
    
    # Преобразуем в datetime
    def hours_to_datetime(hours, base_date):
        total_minutes = int(hours * 60)
        hour = total_minutes // 60
        minute = total_minutes % 60
        
        # Обработка случаев, когда время выходит за пределы суток
        if hour >= 24:
            base_date += timedelta(days=1)
            hour -= 24
        elif hour < 0:
            base_date -= timedelta(days=1)
            hour += 24
            
        return base_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
    
    sunrise = hours_to_datetime(sunrise_time, date)
    sunset = hours_to_datetime(sunset_time, date)
    
    return sunrise, sunset

def set_screen_brightness(brightness):
    """
    Устанавливает яркость экрана через xrandr
    
    Args:
        brightness: значение яркости от 0.1 до 1.0
    """
    try:
        # Ограничиваем значение яркости
        brightness = max(0.1, min(1.0, brightness))
        
        # Выполняем команду xrandr
        subprocess.run([
            '/usr/bin/xrandr', 
            '--output', 'eDP', 
            '--brightness', str(brightness)
        ], check=True)
        
        print(f"Яркость установлена: {brightness:.2f}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"Ошибка при установке яркости: {e}")
        return False
    except Exception as e:
        print(f"Неожиданная ошибка: {e}")
        return False

def calculate_brightness(current_time, sunrise, sunset):
    """
    Вычисляет оптимальную яркость в зависимости от времени суток
    
    Args:
        current_time: текущее время
        sunrise: время восхода
        sunset: время заката
    
    Returns:
        float: значение яркости от 0.1 до 1.0
    """
    
    # Если нет данных о восходе/закате (полярный день/ночь)
    if sunrise is None or sunset is None:
        return 0.8  # Средняя яркость
    
    # Переводим время в минуты от начала дня для удобства расчетов
    def time_to_minutes(dt):
        return dt.hour * 60 + dt.minute
    
    current_minutes = time_to_minutes(current_time)
    sunrise_minutes = time_to_minutes(sunrise)
    sunset_minutes = time_to_minutes(sunset)
    
    # Настройки яркости
    night_brightness = 0.2      # Ночная яркость
    day_brightness = 1.0        # Дневная яркость
    transition_duration = 30    # Длительность перехода в минутах
    
    # Ночное время (до восхода)
    if current_minutes < sunrise_minutes - transition_duration:
        return night_brightness
    
    # Утренний переход (за 30 мин до восхода и 30 мин после)
    elif current_minutes < sunrise_minutes + transition_duration:
        # Плавный переход от ночной к дневной яркости
        progress = (current_minutes - (sunrise_minutes - transition_duration)) / (2 * transition_duration)
        progress = max(0, min(1, progress))
        return night_brightness + (day_brightness - night_brightness) * progress
    
    # Дневное время
    elif current_minutes < sunset_minutes - transition_duration:
        return day_brightness
    
    # Вечерний переход (за 30 мин до заката и 30 мин после)
    elif current_minutes < sunset_minutes + transition_duration:
        # Плавный переход от дневной к ночной яркости
        progress = (current_minutes - (sunset_minutes - transition_duration)) / (2 * transition_duration)
        progress = max(0, min(1, progress))
        return day_brightness - (day_brightness - night_brightness) * progress
    
    # Ночное время (после заката)
    else:
        return night_brightness

def brightness_daemon(latitude, longitude, timezone_offset=0, check_interval=300):
    """
    Демон для автоматической регулировки яркости
    
    Args:
        latitude: широта
        longitude: долгота  
        timezone_offset: смещение часового пояса
        check_interval: интервал проверки в секундах (по умолчанию 5 минут)
    """
    
    print(f"Запуск демона регулировки яркости")
    print(f"Координаты: {latitude}, {longitude}")
    print(f"Интервал проверки: {check_interval} секунд")
    print("Для остановки нажмите Ctrl+C")
    print("-" * 50)
    
    last_date = None
    sunrise = None
    sunset = None
    
    try:
        while True:
            current_time = datetime.now()
            current_date = current_time.date()
            
            # Пересчитываем восход/закат если сменился день
            if last_date != current_date:
                sunrise, sunset = calculate_sunrise_sunset(
                    latitude, longitude, current_time, timezone_offset
                )
                last_date = current_date
                
                if sunrise and sunset:
                    print(f"\nНовый день {current_date}:")
                    print(f"Восход: {sunrise.strftime('%H:%M')}")
                    print(f"Закат:  {sunset.strftime('%H:%M')}")
                else:
                    print(f"\nНовый день {current_date}: полярный день/ночь")
            
            # Вычисляем и устанавливаем яркость
            brightness = calculate_brightness(current_time, sunrise, sunset)
            
            if set_screen_brightness(brightness):
                status = ""
                if sunrise and sunset:
                    if current_time < sunrise:
                        status = "ночь"
                    elif current_time < sunset:
                        status = "день"
                    else:
                        status = "вечер/ночь"
                
                print(f"{current_time.strftime('%H:%M')} - {status} - яркость: {brightness:.2f}")
            
            # Ждем до следующей проверки
            time.sleep(check_interval)
            
    except KeyboardInterrupt:
        print("\nДемон остановлен пользователем")
    except Exception as e:
        print(f"Ошибка в демоне: {e}")

def manual_brightness_check(latitude, longitude, timezone_offset=0):
    """
    Однократная проверка и установка яркости
    """
    current_time = datetime.now()
    sunrise, sunset = calculate_sunrise_sunset(latitude, longitude, current_time, timezone_offset)
    
    print(f"Текущее время: {current_time.strftime('%H:%M')}")
    if sunrise and sunset:
        print(f"Восход: {sunrise.strftime('%H:%M')}")
        print(f"Закат:  {sunset.strftime('%H:%M')}")
    else:
        print("Полярный день/ночь")
    
    brightness = calculate_brightness(current_time, sunrise, sunset)
    print(f"Рекомендуемая яркость: {brightness:.2f}")
    
    if set_screen_brightness(brightness):
        print("Яркость успешно установлена")
    else:
        print("Ошибка при установке яркости")

# Пример использования
if __name__ == "__main__":
    # Координаты (замените на свои)
    LATITUDE = 55.7558   # Москва
    LONGITUDE = 37.6176
    TIMEZONE_OFFSET = 3  # UTC+3
    
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--daemon":
        # Запуск в режиме демона
        brightness_daemon(LATITUDE, LONGITUDE, TIMEZONE_OFFSET, check_interval=300)
    else:
        # Однократная установка яркости
        manual_brightness_check(LATITUDE, LONGITUDE, TIMEZONE_OFFSET)
