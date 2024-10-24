-- Drop the triggers first
DROP TRIGGER IF EXISTS trigger_set_deleted_at ON retail_transactions;
DROP TRIGGER IF EXISTS trigger_update_timestamp ON retail_transactions;
DROP TRIGGER IF EXISTS trigger_log_delete ON retail_transactions_archive;

-- Drop the functions
DROP FUNCTION IF EXISTS set_deleted_at();
DROP FUNCTION IF EXISTS update_timestamp();
DROP FUNCtiON IF EXISTS log_delete();

-- Drop the retail_transactions table
DROP TABLE IF EXISTS retail_transactions;
DROP TABLE IF EXISTS retail_transactions_archive;

-- Drop the transaction_status ENUM type
DROP TYPE IF EXISTS transaction_status;
