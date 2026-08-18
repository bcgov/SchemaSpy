-- Example schema for SchemaSpy to document: a small library catalog.

CREATE TABLE authors (
    author_id   SERIAL PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    country     VARCHAR(100)
);

CREATE TABLE genres (
    genre_id    SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE books (
    book_id         SERIAL PRIMARY KEY,
    title           VARCHAR(255) NOT NULL,
    author_id       INTEGER NOT NULL REFERENCES authors(author_id),
    genre_id        INTEGER REFERENCES genres(genre_id),
    published_year  SMALLINT,
    isbn            VARCHAR(20) UNIQUE
);

CREATE TABLE members (
    member_id   SERIAL PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(255) UNIQUE NOT NULL,
    joined_on   DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE loans (
    loan_id     SERIAL PRIMARY KEY,
    book_id     INTEGER NOT NULL REFERENCES books(book_id),
    member_id   INTEGER NOT NULL REFERENCES members(member_id),
    loaned_on   DATE NOT NULL DEFAULT CURRENT_DATE,
    returned_on DATE
);

INSERT INTO authors (first_name, last_name, country) VALUES
    ('Ursula', 'Le Guin', 'USA'),
    ('Isaac', 'Asimov', 'USA'),
    ('Agatha', 'Christie', 'UK');

INSERT INTO genres (name) VALUES
    ('Science Fiction'),
    ('Mystery'),
    ('Fantasy');

INSERT INTO books (title, author_id, genre_id, published_year, isbn) VALUES
    ('A Wizard of Earthsea', 1, 3, 1968, '978-0-547-05539-8'),
    ('Foundation', 2, 1, 1951, '978-0-553-29335-0'),
    ('Murder on the Orient Express', 3, 2, 1934, '978-0-06-269342-4');

INSERT INTO members (first_name, last_name, email) VALUES
    ('Jane', 'Doe', 'jane.doe@example.com'),
    ('John', 'Smith', 'john.smith@example.com');

INSERT INTO loans (book_id, member_id, loaned_on, returned_on) VALUES
    (1, 1, CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE - INTERVAL '3 days'),
    (2, 2, CURRENT_DATE - INTERVAL '2 days', NULL);
