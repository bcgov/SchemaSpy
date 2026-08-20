-- Example schema for SchemaSpy to document: a small library catalog.

IF DB_ID('example') IS NULL
    CREATE DATABASE example;
GO

USE example;
GO

CREATE TABLE authors (
    author_id   INT IDENTITY PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    country     VARCHAR(100)
);

CREATE TABLE genres (
    genre_id    INT IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE books (
    book_id         INT IDENTITY PRIMARY KEY,
    title           VARCHAR(255) NOT NULL,
    author_id       INT NOT NULL REFERENCES authors(author_id),
    genre_id        INT REFERENCES genres(genre_id),
    published_year  SMALLINT,
    isbn            VARCHAR(20) UNIQUE
);

CREATE TABLE members (
    member_id   INT IDENTITY PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(255) UNIQUE NOT NULL,
    joined_on   DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE)
);

CREATE TABLE loans (
    loan_id     INT IDENTITY PRIMARY KEY,
    book_id     INT NOT NULL REFERENCES books(book_id),
    member_id   INT NOT NULL REFERENCES members(member_id),
    loaned_on   DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    returned_on DATE
);
GO

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
    (1, 1, DATEADD(DAY, -10, CAST(GETDATE() AS DATE)), DATEADD(DAY, -3, CAST(GETDATE() AS DATE))),
    (2, 2, DATEADD(DAY, -2, CAST(GETDATE() AS DATE)), NULL);
GO
