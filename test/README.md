# Tests

Dumping test scripts and notes here.


## Locust

```bash
% python test.py 
 * Serving Flask app 'test'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.2.56:5000
Press CTRL+C to quit
127.0.0.1 - - [12/Dec/2022 12:36:57] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [12/Dec/2022 12:36:57] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [12/Dec/2022 12:36:58] "GET / HTTP/1.1" 200 -
```


```bash
% locust
[2022-12-12 12:36:30,233] CA10MACKFALJG5J/INFO/locust.main: Starting web interface at http://0.0.0.0:8089 (accepting connections from all network interfaces)
[2022-12-12 12:36:30,246] CA10MACKFALJG5J/INFO/locust.main: Starting Locust 2.13.2
[2022-12-12 12:36:57,958] CA10MACKFALJG5J/INFO/locust.runners: Ramping to 10 users at a rate of 2.00 per second
[2022-12-12 12:37:01,968] CA10MACKFALJG5J/INFO/locust.runners: All users spawned: {"WebsiteTestUser": 10} (10 total users)
KeyboardInterrupt
2022-12-12T17:37:43Z
[2022-12-12 12:37:43,421] CA10MACKFALJG5J/INFO/locust.main: Shutting down (exit code 0)
Type     Name                                                                          # reqs      # fails |    Avg     Min     Max    Med |   req/s  failures/s
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
GET      /                                                                                 79     0(0.00%) |     10       6      22     10 |    5.67        0.00
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
         Aggregated                                                                        79     0(0.00%) |     10       6      22     10 |    5.67        0.00

Response time percentiles (approximated)
Type     Name                                                                                  50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
GET      /                                                                                      10     10     10     11     16     19     23     23     23     23     23     79
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                                                                             10     10     10     11     16     19     23     23     23     23     23     79
```
