SubdomainFu.tld_size = 1 # sets for current environment
SubdomainFu.tld_sizes = {:development => 0, # e.g. localhost
                         :test => 0,
                         :production => 1}  # e.g. peanut.com

# default to www.peanut.com instead of peanut.com
SubdomainFu.preferred_mirror = "www"
