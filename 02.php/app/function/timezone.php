<?php

/**
 * Web、命令行和守护进程统一使用 Docker Compose 传入的 TZ。
 * cron 未继承 TZ 时读取系统时区；均未设置时保留原有中国时区默认值。
 * 错误配置应明确报错，避免静默使用 UTC。
 */
function funSetTimezone()
{
    $timezone = getenv('TZ');
    if (($timezone === false || $timezone === '') && is_readable('/etc/timezone')) {
        $timezone = trim(file_get_contents('/etc/timezone'));
    }
    if ($timezone === false || $timezone === '') {
        $timezone = 'Asia/Shanghai';
    }

    if (!in_array($timezone, timezone_identifiers_list(DateTimeZone::ALL_WITH_BC), true)) {
        throw new RuntimeException('Invalid TZ timezone: ' . $timezone);
    }

    if (!date_default_timezone_set($timezone)) {
        throw new RuntimeException('Unable to set TZ timezone: ' . $timezone);
    }
}
