<?php

// Small no-framework regression tests for the PHP 8.4 migration.
require_once __DIR__ . '/../02.php/app/function/message.php';
require_once __DIR__ . '/../02.php/app/function/array.php';
require_once __DIR__ . '/../02.php/extension/Medoo-1.7.10/src/Medoo.php';

$columns = ['name' => ['type' => 'string', 'notNull' => true]];
$cases = [
    [null, 0],
    ['unexpected scalar', 0],
    [[], 0],
    [['other' => 'value'], 0],
    [['name' => 123], 0],
    [['name' => ''], 0],
    [['name' => 'svn'], 1]
];

foreach ($cases as [$input, $expected]) {
    $actual = funCheckForm($input, $columns)['status'];
    if ($actual !== $expected) {
        throw new RuntimeException('Unexpected form validation result');
    }
}

if (!in_array('sqlite', PDO::getAvailableDrivers(), true)) {
    if (in_array('--require-sqlite', $argv, true)) {
        throw new RuntimeException('pdo_sqlite is required');
    }
    fwrite(STDOUT, "Form validation OK; SQLite smoke skipped (pdo_sqlite not installed)\n");
    exit(0);
}

$path = tempnam(sys_get_temp_dir(), 'svnadmin-test-');
try {
    $database = new Medoo\Medoo([
        'database_type' => 'sqlite',
        'database_file' => $path,
        'option' => [PDO::ATTR_ERRMODE => PDO::ERRMODE_SILENT]
    ]);
    $database->query('CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $database->insert('items', ['name' => 'svn']);
    if ($database->get('items', 'name', ['id' => 1]) !== 'svn') {
        throw new RuntimeException('Medoo SQLite round trip failed');
    }
} finally {
    unset($database);
    unlink($path);
}

echo "PHP 8.4 smoke checks passed\n";
