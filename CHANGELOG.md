# 2.0.0 (26rd August 2015)
* Removed session_header from configuration options
# Now passes the whole env to the session Proc

# 1.2.1 (24rd July 2015)
* Using env['HTTP_X_REQUEST_ID'] or env['rack-timeout.info'][:id] or generate unique hex to identify request batch

# 1.2.0 (23rd July 2015)
* Removed logging, added batch START and END logs

# 1.1.4 (17th July 2015)
* Added batch session

# 1.1.3 (25th June 2015)
* Fixed nested hash to url_encoded

# 1.1.2 (17th February 2015)
* Added logs

# 1.1.1 (31st December 2014)
* First stable version