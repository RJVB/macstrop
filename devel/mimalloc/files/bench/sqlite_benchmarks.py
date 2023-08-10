# adapted from https://gist.github.com/slidenerd/cc278cd6c2f04943979a2079b249e810

import sqlite3
import time
import random
import string
import os
import timeit
from functools import wraps
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
import threading
import os

"""
This test is being done to determine the best way to write and read from SQLite database. We follow 3 approaches below
1) Read and write without any threads (the methods with the word normal on it)
2) Read and write with Threads
3) Read and write with processes

Single Table
Our sample dataset is a dummy generated OHLC dataset with a symbol, timestamp, and 6 fake values for ohlc and volumefrom, volumeto

Reads
1) Normal method takes about 0.25 seconds to read
2) Threaded method takes 10 seconds
3) Processing takes 0.25 seconds to read

Winner: Processing and Normal

Writes
1) Normal method takes about 1.5 seconds to write
2) Threaded method takes about 30 seconds
3) Processing takes about 30 seconds

Winner: Normal

Note: All records are not written using the threaded and processed write methods. Threaded and processed write methods obviously run into database locked errors as the writes are queued up
SQlite only queues up writes to a certain threshold and then throws sqlite3.OperationalError indicating database is locked.
The ideal way is to retry inserting the same chunk again but there is no point as the method execution for parallel insertion takes more tine than a sequential read even without retrying
the locked/failed inserts
Without retrying, 97% of the rows were written and still took 10x more time than a sequential write


Strategies to takeaway:
1) Prefer reading SQLite and writing it in the same thread
2) If you must do multithreading, use multiprocessing to read which has more or less the same performance and defer to single threaded write operations
3) DO NOT USE THREADING for reads and writes as it is 10x slower on both, you can thank the GIL for that

Multiple Tables
Our sample database has 2 tables now both having the same ohlc data and our goal is to test reading and writing tables in parallel using Processes and Threads
One thing we observe from our previous experiment is that writing multiple symbols in parallel is deterimental regardless of whether we use threads or processes
Reading multiple symbols in parallel only helps when we use Processes

So the approach here is not to divide on the basis of symbols, rather let's divide our reading and writing operation such that we read/write tables in parallel
Read/Write 2 tables
1) One after the other in sequential fashion
2) In parallel using Threads
3) In parallel using Processes

Reads
1) Sequential takes about 0.5 seconds
2) Threading takes about 2 to 3 seconds, clearly a loser
3) Processing takes only 0.2 seconds!!!

Winner: Multiprocessing hands down! Whenever you want to read tables in parallel, definitely consider multiprocessing

Writes
1) Sequential takes about 2 seconds to write
2) Threading takes about 4 to 5 seconds
3) Multiprocessing takes about 4 to 5 seconds

Clearly sequential writing is the fastest way to write stuff to the SQlite database even if you have multiple tables
"""

#database_file = os.path.realpath('test.db')

# we're used in a memory allocator benchmark, so use an in-memory database.
# this means we need to create a connection before calling the BM functions
# and out-comment all connect() and close() calls in those functions.
database_file = ':memory:'

create_statement = 'CREATE TABLE IF NOT EXISTS database_threading_test (symbol TEXT, ts INTEGER, o REAL, h REAL, l REAL, c REAL, vf REAL, vt REAL, PRIMARY KEY(symbol, ts))'
insert_statement = 'INSERT INTO database_threading_test VALUES(?,?,?,?,?,?,?,?)'
select_statement = 'SELECT * from database_threading_test'

create_statement2 = 'CREATE TABLE IF NOT EXISTS database_threading_test2 (symbol TEXT, ts INTEGER, o REAL, h REAL, l REAL, c REAL, vf REAL, vt REAL, PRIMARY KEY(symbol, ts))'
insert_statement2 = 'INSERT INTO database_threading_test2 VALUES(?,?,?,?,?,?,?,?)'
select_statement2 = 'SELECT * from database_threading_test2'

def time_stuff(some_function):
    def wrapper(*args, **kwargs):
        t0 = timeit.default_timer()
        value = some_function(*args, **kwargs)
        #print(some_function, ': ', timeit.default_timer() - t0, 'seconds')
        return value
    return wrapper

def generate_values(count=200):
    end = int(time.time()) - int(time.time()) % 900
    symbol = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(10))
    ts = list(range(end - count * 900, end, 900))
    for i in range(count):
        yield (symbol, ts[i], random.random() * 1000, random.random() * 1000, random.random() * 1000, random.random() * 1000, random.random() * 1e9, random.random() * 1e5)

def generate_values_list(symbols=1000,count=200):
    values = []
    for _ in range(symbols):
        values.extend(generate_values(count))
    return values

@time_stuff
def sequential_read():
    """
    Read rows one after the other from a single thread

    100k records in the database, 1000 symbols, 100 rows
    First run
    0.25139795300037804 seconds
    Second run

    Third run
    """
    #conn = sqlite3.connect(database_file)
    try:
        with conn:
            conn.execute(create_statement)
            results = conn.execute(select_statement).fetchall()
            #print(len(results))
        #conn.close()
    except sqlite3.OperationalError as e:
        print(e)

@time_stuff
def sequential_write():
    """
    Insert rows one after the other from a single thread

    1000 symbols, 100 rows
    First run
    2.279409104000024 seconds
    Second run
    2.3364172020001206 seconds
    Third run
    """
    l = generate_values_list()
    #conn = sqlite3.connect(database_file)
    try:
        with conn:
            conn.execute(create_statement)
            conn.executemany(insert_statement, l)
        #conn.close()

    except sqlite3.OperationalError as e:
        print(e)

def read_task(symbol):
    """
    Task to read all rows of a given symbol from different threads
    """
    results = []
    #conn = sqlite3.connect(database_file)
    try:
        with conn:
            results = conn.execute("SELECT * FROM database_threading_test WHERE symbol=?", symbol).fetchall()
        #conn.close()
    except sqlite3.OperationalError as e:
        print(e)
    finally:
        return results

@time_stuff
def threaded_read():
    """
    Get all the symbols from the database
    Assign chunks of 50 symbols to each thread worker and let them read all rows for the given symbol

    1000 symbols, 100 rows per symbol
    First run
    9.429676861000189 seconds
    Second run
    10.18928106400017 seconds
    Third run
    10.382290903000467 seconds
    """
    #conn = sqlite3.connect(database_file)
    symbols = conn.execute("SELECT DISTINCT SYMBOL from database_threading_test").fetchall()
    with ThreadPoolExecutor(max_workers=8) as e:
        results = e.map(read_task, symbols, chunksize=50)
        for result in results:
            pass
    #conn.close()

@time_stuff
def multiprocessed_read():
    """
    Get all the symbols from the database
    Assign chunks of 50 symbols to each process worker and let them read all rows for the given symbol

    1000 symbols, 100 rows
    First run
    0.2484774920012569 seconds!!!
    Second run
    0.24322178500005975 seconds
    Third run
    0.2863524549993599 seconds
    """
    #conn = sqlite3.connect(database_file)
    symbols = conn.execute("SELECT DISTINCT SYMBOL from database_threading_test").fetchall()
    with ProcessPoolExecutor(max_workers=8) as e:
        results = e.map(read_task, symbols, chunksize=50)
        for result in results:
            pass

def write_task(n):
    """
    Insert rows for a given symbol in the database from multiple threads
    We ignore the database locked errors here. Ideal case would be to retry but there is no point writing code for that if it takes longer than a sequential write even without database locke errors
    """
    #conn = sqlite3.connect(database_file)
    data = list(generate_values())
    try:
        with conn:
            conn.executemany(insert_statement,data)
    except sqlite3.OperationalError as e:
        #print("Database locked",e)
        pass
    finally:
        #conn.close()
        return len(data)

@time_stuff
def threaded_write():
    """
    Insert 100 rows per symbol in parallel using multiple threads

    Prone to database locked errors so all rows may not be written
    Takes 20x the amount of time as a normal write
    1000 symbols, 100 rows
    First run
    28.17819765000013 seconds
    Second run
    25.557972323000058 seconds
    Third run
    """
    symbols = [i for i in range(1000)]
    with ThreadPoolExecutor(max_workers=8) as e:
        results = e.map(write_task, symbols, chunksize=50)
        for result in results:
            pass

@time_stuff
def multiprocessed_write():
    """
    Insert 100 rows per symbol in parallel using multiple processes

    1000 symbols, 100 rows
    First run
    30.09209805699993 seconds
    Second run
    27.502465319000066 seconds
    Third run
    """
    symbols = [i for i in range(1000)]
    with ProcessPoolExecutor(max_workers=8) as e:
        results = e.map(write_task, symbols, chunksize=50)
        for result in results:
            pass

@time_stuff
def sequential_multidatabase_read():
    """
    Read 100 rows per symbol, 1000 symbols from 2 tables one after the other

    2 tables
    1000 symbols 100 rows
    1000 symbols 100 rows
    Read them one after the other

    First run
    0.4853558899994823 seconds
    Second run
    0.48433448700052395 seconds
    Third run
    0.5015649520009902 seconds
    """
    #conn = sqlite3.connect(database_file)
    try:
        with conn:
            conn.execute(create_statement)
            conn.execute(create_statement2)
            results = conn.execute(select_statement).fetchall()
            results2 = conn.execute(select_statement2).fetchall()
        #conn.close()
    except sqlite3.OperationalError as e:
        print(e)

@time_stuff
def sequential_multidatabase_write():
    """
    Insert 100 rows per symbol, 1000 symbols into 2 tables one after the other

    2 tables
    1000 symbols 100 rows
    1000 symbols 100 rows
    Write them one after the other

    First run
    1.9666547140004695 seconds
    Second run
    2.271214049000264 seconds
    Third run
    2.2556295950016647 seconds
    """
    l = generate_values_list()
    l2 = generate_values_list()
    #conn = sqlite3.connect(database_file)
    try:
        with conn:
            conn.execute(create_statement)
            conn.execute(create_statement2)
            conn.executemany(insert_statement, l)
            conn.executemany(insert_statement2, l2)
        #conn.close()

    except sqlite3.OperationalError as e:
        print(e)

def multidatabase_read_task(table_name):
    #conn = sqlite3.connect(database_file)
    results = conn.execute('SELECT * from ' +  table_name).fetchall()
    print(table_name, len(results))
    #conn.close()

@time_stuff
def threaded_multidatabase_read():
    """
    Instead of dividing on the basis of symbols which was done in threaded_read and threaded_write methods above and avail no benefits, lets try to read tables in parallel
    This method has 2 databases from which we try to read in parallel using threads
    
    First run
    2.523770304000209 seconds
    Second run
    1.9435538449997694 seconds
    Third run
    3.6319471670012717 seconds
    Fourth run
    1.8723913399990124 seconds
    Fifth run
    3.243724142999781 seconds
    """
    #conn = sqlite3.connect(database_file)
    table_names = ['database_threading_test', 'database_threading_test2']
    with ThreadPoolExecutor(max_workers=8) as e:
        results = e.map(multidatabase_read_task, table_names)
        for result in results:
            pass
    #conn.close()

@time_stuff
def multiprocessed_multidatabase_read():
    """
    Lets read multiple tables in parallel using processes
    First run
    0.27727104500081623 seconds
    Second run
    0.2779598149991216 seconds
    Third run
    0.2765654220002034 seconds
    """
    #conn = sqlite3.connect(database_file)
    table_names = ['database_threading_test', 'database_threading_test2']
    with ProcessPoolExecutor(max_workers=8) as e:
        results = e.map(multidatabase_read_task, table_names)
        for result in results:
            pass
    #conn.close()

def multidatabase_write_task(table_name):
    #conn = sqlite3.connect(database_file)
    l = generate_values_list()
    with conn:
        conn.execute("CREATE TABLE IF NOT EXISTS " + table_name + " (symbol TEXT, ts INTEGER, o REAL, h REAL, l REAL, c REAL, vf REAL, vt REAL, PRIMARY KEY(symbol, ts))")
        results = conn.executemany('INSERT INTO ' +  table_name + ' VALUES(?,?,?,?,?,?,?,?)',l)
        print(table_name)
    #conn.close()

@time_stuff
def threaded_multidatabase_write():
    """
    Write to separate tables at the same time using threads
    First run
    4.800784029001079 seconds
    Second run
    4.229595732000234 seconds
    Third run
    4.004078085999936 seconds
    """
    #conn = sqlite3.connect(database_file)
    table_names = ['database_threading_test', 'database_threading_test2']
    with ThreadPoolExecutor(max_workers=8) as e:
        results = e.map(multidatabase_write_task, table_names)
        for result in results:
            pass
    #conn.close()

@time_stuff
def multiprocessed_multidatabase_write():
    """
    Write to separate tables at the same time using processes
    First run
    4.518384539000181 seconds
    Second run
    5.36600625400024 seconds
    Third run
    4.202942468000401 seconds
    """
    #conn = sqlite3.connect(database_file)
    table_names = ['database_threading_test', 'database_threading_test2']
    with ProcessPoolExecutor(max_workers=8) as e:
        results = e.map(multidatabase_write_task, table_names)
        for result in results:
            pass
    #conn.close()

# ------------

# os.remove(database_file)

conn = sqlite3.connect(database_file)
sequential_write()
sequential_read()

threaded_write()
threaded_read()
# multiprocessed_write()
# multiprocessed_read()

sequential_multidatabase_write()
sequential_multidatabase_read();

# threaded_multidatabase_write()
# threaded_multidatabase_read()
# multiprocessed_multidatabase_write()
# multiprocessed_multidatabase_read()

