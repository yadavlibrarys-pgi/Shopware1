-- =============================================
-- DRISHTI DIGITAL LIBRARY - SUPABASE SQL SETUP
-- =============================================
-- Ye SQL queries Supabase ke SQL Editor me paste karke run karo
-- Sab tables timestamps ke sath banenge (created_at, updated_at)
-- =============================================

-- 1. SETTINGS TABLE - Library ki settings store karta hai
CREATE TABLE IF NOT EXISTS settings (
    id INTEGER PRIMARY KEY DEFAULT 1,
    owner_mobile TEXT,
    total_seats INTEGER DEFAULT 50,
    whatsapp_link TEXT DEFAULT '',
    upi_id TEXT DEFAULT '',
    library_lat DOUBLE PRECISION DEFAULT 25.6127,
    library_lng DOUBLE PRECISION DEFAULT 85.1589,
    library_range INTEGER DEFAULT 30,
    location_set BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default settings row insert karo
INSERT INTO settings (id, total_seats) VALUES (1, 50) ON CONFLICT (id) DO NOTHING;

-- 2. STUDENTS TABLE - Sabhi student records
CREATE TABLE IF NOT EXISTS students (
    id BIGSERIAL,
    mobile_number TEXT PRIMARY KEY,
    full_name TEXT,
    father_name TEXT,
    address TEXT,
    admission_date TEXT,
    user_name TEXT,
    password TEXT,
    profile_pic TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. WOW SEATS TABLE - Seat allocation aur booking details
CREATE TABLE IF NOT EXISTS wow_seats (
    id BIGSERIAL,
    mobile TEXT PRIMARY KEY,
    seat_no TEXT DEFAULT '',
    batch_string TEXT DEFAULT 'N/A',
    shifts INTEGER DEFAULT 0,
    payment NUMERIC DEFAULT 0,
    custom_rate NUMERIC DEFAULT 0,
    fixed_total_payment NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. BOOKINGS TABLE - Graph/Seat bookings
CREATE TABLE IF NOT EXISTS bookings (
    id BIGSERIAL PRIMARY KEY,
    seat INTEGER NOT NULL,
    shift INTEGER NOT NULL,
    name TEXT,
    address TEXT,
    mobile TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. PAYMENTS TABLE - Payment records with timestamps
CREATE TABLE IF NOT EXISTS payments (
    id BIGSERIAL,
    mobile TEXT NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    required_amount NUMERIC DEFAULT 0,
    paid_amount NUMERIC DEFAULT 0,
    timestamp TEXT,
    transaction_id TEXT,
    status TEXT DEFAULT 'paid',
    completion_timestamp TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (mobile, year, month)
);

-- 6. ATTENDANCE TABLE - Attendance records with timestamps
CREATE TABLE IF NOT EXISTS attendance (
    id BIGSERIAL,
    mobile TEXT NOT NULL,
    date TEXT NOT NULL,
    times JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (mobile, date)
);

-- =============================================
-- INDEXES - Fast queries ke liye
-- =============================================
CREATE INDEX IF NOT EXISTS idx_students_created ON students(created_at);
CREATE INDEX IF NOT EXISTS idx_students_name ON students(full_name);
CREATE INDEX IF NOT EXISTS idx_bookings_seat ON bookings(seat, shift);
CREATE INDEX IF NOT EXISTS idx_bookings_mobile ON bookings(mobile);
CREATE INDEX IF NOT EXISTS idx_payments_mobile ON payments(mobile);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_attendance_mobile ON attendance(mobile);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);

-- =============================================
-- ROW LEVEL SECURITY (RLS) - Public access enable karo
-- =============================================
-- NOTE: Development ke liye RLS disable hai
-- Production me enable karke proper policies lagao

ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE wow_seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Public access policies (anon key se access ho sake)
CREATE POLICY "Allow public access on settings" ON settings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access on students" ON students FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access on wow_seats" ON wow_seats FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access on bookings" ON bookings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access on payments" ON payments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public access on attendance" ON attendance FOR ALL USING (true) WITH CHECK (true);

-- =============================================
-- AUTO UPDATE TIMESTAMP TRIGGER
-- Jab bhi row update ho, updated_at automatic change hoga
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wow_seats_updated_at BEFORE UPDATE ON wow_seats 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- USEFUL QUERIES (Reference ke liye)
-- =============================================

-- Sabhi students dekho:
-- SELECT * FROM students ORDER BY created_at;

-- Kisi student ki attendance dekho:
-- SELECT * FROM attendance WHERE mobile = '1234567890' ORDER BY date DESC;

-- Payment status check karo:
-- SELECT * FROM payments WHERE status = 'pending';

-- Seat bookings dekho:
-- SELECT * FROM bookings ORDER BY seat, shift;

-- Monthly payment summary:
-- SELECT mobile, year, month, paid_amount, required_amount, status, timestamp, updated_at 
-- FROM payments ORDER BY year DESC, month DESC;

-- Student attendance summary (current month):
-- SELECT a.mobile, s.full_name, a.date, a.times, a.updated_at
-- FROM attendance a 
-- JOIN students s ON a.mobile = s.mobile_number
-- WHERE a.date LIKE '2026-03%'
-- ORDER BY a.date DESC;
