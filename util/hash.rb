##
# Generates a hash of the input (first argument) using the OpenSSL SHA224 hash algorithm. 
#
# See http://ruby-doc.org/stdlib-1.9.3/libdoc/openssl/rdoc/OpenSSL/Digest.html for documentation.
#
# Run with: ruby hash.rb <STRING TO HASH>
#
# Returns error code 1 to system if the script fails to hash. On UNIX check the system error 
# code with `echo $?`
#

require 'OpenSSL'
require 'Base64'

if ARGV.length < 1
    puts "Requires exactly one argument, the string to hash.\nRun with `ruby hash.rb <STRING>`\n"
    exit 1
else
    x =  OpenSSL::Digest.digest("SHA224", ARGV[0]) 
    puts Base64.strict_encode64(x)
    exit 0
end


