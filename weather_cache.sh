#!/bin/bash

CACHE_FILE="/tmp/weather_cache.txt"
CACHE_TIME_FILE="/tmp/weather_cache_time.txt"
CACHE_DURATION=3600  # 1 час в секундах

# Проверяем, существует ли кэш и не устарел ли он
if [ -f "$CACHE_TIME_FILE" ] && [ -f "$CACHE_FILE" ]; then
    LAST_UPDATE=$(cat "$CACHE_TIME_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))
    
    if [ $TIME_DIFF -lt $CACHE_DURATION ]; then
        # Кэш актуален, возвращаем сохраненные данные
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Кэш устарел или не существует, делаем новый запрос
WEATHER_DATA=$(curl -s 'https://api.weather.yandex.ru/v2/forecast?lat=56.00127&lon=37.48090' -H 'X-Yandex-Weather-Key: cfc4ec83-054f-457e-b0e0-bd491916bc26' | jq -r '.fact | "\(.temp)°C \(.humidity)% \(.wind_speed)м/с"' 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$WEATHER_DATA" ]; then
    # Сохраняем данные и время обновления
    echo "$WEATHER_DATA" > "$CACHE_FILE"
    date +%s > "$CACHE_TIME_FILE"
    echo "$WEATHER_DATA"
else
    # Если запрос неудачен, возвращаем старые данные или N/A
    if [ -f "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        echo "N/A"
    fi
fi
