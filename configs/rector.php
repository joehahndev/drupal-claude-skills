<?php

/**
 * @file
 * Rector configuration for automated Drupal deprecation fixes.
 *
 * Always dry-run first:
 *   vendor/bin/rector process --dry-run
 * Then review the diff before:
 *   vendor/bin/rector process
 *
 * Rector fixes mechanical deprecations. It will NOT convert procedural hooks to
 * OOP #[Hook] attributes correctly in every case — review those by hand.
 */

declare(strict_types=1);

use DrupalFinder\DrupalFinderComposerRuntime;
use DrupalRector\Set\Drupal10SetList;
use DrupalRector\Set\Drupal11SetList;
use Rector\Config\RectorConfig;

return static function (RectorConfig $rectorConfig): void {
  $rectorConfig->sets([
    Drupal10SetList::DRUPAL_10,
    Drupal11SetList::DRUPAL_11,
  ]);

  $drupalFinder = new DrupalFinderComposerRuntime();
  $drupalRoot = $drupalFinder->getDrupalRoot();
  $rectorConfig->autoloadPaths([
    $drupalRoot . '/core',
    $drupalRoot . '/modules',
    $drupalRoot . '/themes',
    $drupalRoot . '/profiles',
  ]);

  $rectorConfig->paths([
    $drupalRoot . '/modules/custom',
    $drupalRoot . '/themes/custom',
    $drupalRoot . '/profiles/custom',
  ]);

  $rectorConfig->skip([
    '*/vendor/*',
    '*/node_modules/*',
    '*/contrib/*',
  ]);

  $rectorConfig->fileExtensions([
    'php',
    'module',
    'theme',
    'install',
    'profile',
    'inc',
    'engine',
  ]);

  $rectorConfig->importNames(TRUE, FALSE);
  $rectorConfig->importShortClasses(FALSE);
};
