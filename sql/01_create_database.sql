-- ============================================================================
-- Project: Grocery Store Management SQL Database
-- File: 01_create_database.sql
-- Description: Idempotent database creation script with production character sets
-- Author: Mahaboob Subhani Shaik
-- Target DBMS: MySQL 8.x
-- ============================================================================

-- Step 1: Create Database if it does not already exist
-- Character Set: utf8mb4 (supports full Unicode, including emojis and international characters)
-- Collation: utf8mb4_unicode_ci (standard Unicode case-insensitive sorting and comparison)
CREATE DATABASE IF NOT EXISTS grocery_store
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Step 2: Switch to the newly created database context
USE grocery_store;

-- Verification query
SELECT 
    SCHEMA_NAME AS database_name,
    DEFAULT_CHARACTER_SET_NAME AS character_set,
    DEFAULT_COLLATION_NAME AS collation_name
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'grocery_store';
