-- Create enum status
CREATE TYPE transaction_status AS ENUM ('INITIATED', 'PROCESSING', 'DONE', 'CANCELLED');

-- Create the retail_transactions table
CREATE TABLE IF NOT EXISTS retail_transactions (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(255) NOT NULL,
    last_status transaction_status NOT NULL,
    pos_origin VARCHAR(255),
    pos_destination VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Trigger function for setting updated_at when the row is updated
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for setting deleted_at when last_status is 'DONE'
CREATE OR REPLACE FUNCTION set_deleted_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.last_status = 'DONE' THEN
        NEW.deleted_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at column on row update
CREATE TRIGGER trigger_update_timestamp
BEFORE UPDATE ON retail_transactions
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Trigger to update deleted_at when last_status becomes 'DONE'
CREATE TRIGGER trigger_set_deleted_at
BEFORE UPDATE ON retail_transactions
FOR EACH ROW
EXECUTE FUNCTION set_deleted_at();

-- HARD DELETE CASE
-- Create the retail_transactions_archive table
CREATE TABLE IF NOT EXISTS retail_transactions_archive (
    customer_id VARCHAR(255) NOT NULL,
    deleted_at TIMESTAMP 
);

-- Trigger function for insert record to archive table when row deleted
CREATE OR REPLACE FUNCTION log_delete()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM retail_transactions_archive WHERE customer_id = old.customer_id;
    INSERT INTO retail_transactions_archive (customer_id, deleted_at)
    VALUES (old.customer_id, now());
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger for insert record to archive table when row deleted
CREATE TRIGGER trigger_log_delete
AFTER DELETE ON retail_transactions
FOR EACH ROW
EXECUTE FUNCTION log_delete();

-- Insert dummy records
INSERT INTO retail_transactions (customer_id, last_status, pos_origin, pos_destination)
VALUES 
('CUST001', 'INITIATED', 'Store1', 'Store2'),
('CUST002', 'PROCESSING', 'Store2', 'Store3'),
('CUST004', 'CANCELLED', 'Store3', 'Store2');
