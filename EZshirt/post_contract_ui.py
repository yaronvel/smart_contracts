from pycoin.serialize import b2h, h2b
import rlp
from ethereum import utils, transactions
import requests
import json
import time
from ethereum.abi import ContractTranslator
import getopt, sys


use_ether_scan = True
ether_scan_api_key = '66FCG5X3HSVW23R2ZJTFJEKWMKKGJVIQXK'
local_url = "http://localhost:8545/jsonrpc"

def merge_two_dicts(x, y):
    '''Given two dicts, merge them into a new dict as a shallow copy.'''
    z = x.copy()
    z.update(y)
    return z

def etherscan_call( method_name, params ):
    url = "https://testnet.etherscan.io/api"
    payload = {"module" : "proxy",
               "action" : method_name,
               "apikey" : ether_scan_api_key }
    payload = merge_two_dicts(payload, params[0] )
    response = requests.post( url, params=payload )
    return response.json()[ 'result' ]
    
    
def json_call( method_name, params ):
    if use_ether_scan:
        return etherscan_call( method_name, params )
    url = local_url
    headers = {'content-type': 'application/json'}
    
    payload = { "method": method_name,
                "params": params,
                "jsonrpc": "2.0",
                "id": 1,
                }
    response = requests.post(url, data=json.dumps(payload), headers=headers).json()
    return response[ 'result' ]

def get_num_transactions( address ):
    if use_ether_scan:
        params = [{ "address" : "0x" + address, "tag" : "pending" }]
    else:
        params = [ "0x" + address, "pending" ]
    nonce = json_call( "eth_getTransactionCount", params )
    return nonce 

def get_gas_price_in_wei( ):
    if use_ether_scan:
        return "0x%x" % 20000000000 # 20 gwei
    return json_call( "eth_gasPrice", [] )

def eval_startgas( src, dst, value, data, gas_price ):
    if use_ether_scan or True:
        return "0x%x" % (4712388/2) # hardcoded max gas
        
    params = { "value" : "0x" + str(value),
               "pasPrice" : gas_price }
    if len(data) > 0:
        params["data"] = "0x" + str(data)
    if len(dst) > 0:
        params["to"] = "0x" + dst
    return json_call( "eth_estimateGas", [params] )

def make_transaction( src_priv_key, dst_address, value, data ):
    src_address = b2h( utils.privtoaddr(src_priv_key) )
    nonce = get_num_transactions( src_address )
    gas_price = get_gas_price_in_wei()
    data_as_string = b2h(data)
    start_gas = eval_startgas( src_address, dst_address, value, data_as_string, gas_price )
    
    nonce = int( nonce, 16 )
    gas_price = int( gas_price, 16 )
    start_gas = int( start_gas, 16 ) + 100000
    
    tx = transactions.Transaction( nonce,
                                   gas_price,
                                   start_gas,
                                   dst_address,
                                   value,
                                   data ).sign(src_priv_key)
    
    
                                   
    tx_hex  = b2h(rlp.encode(tx))
    tx_hash = b2h( tx.hash )
    if use_ether_scan:
        params = [{"hex" : "0x" + tx_hex }]
    else:
        params = ["0x" + tx_hex]
    return_value = json_call( "eth_sendRawTransaction", params )                       
    if return_value == "0x0000000000000000000000000000000000000000000000000000000000000000":
        print "Transaction failed"
        return False
    wait_for_confirmation(tx_hash)
    return return_value        
        
def call_function( priv_key, value, contract_hash, contract_abi, function_name, args ):
    translator = ContractTranslator(contract_abi)
    call = translator.encode_function_call(function_name, args)
    return make_transaction(priv_key, contract_hash, value, call)
    

def call_const_function( priv_key, value, contract_hash, contract_abi, function_name, args ):
    src_address = b2h( utils.privtoaddr(priv_key) )    
    translator = ContractTranslator(contract_abi)
    call = translator.encode_function_call(function_name, args)  
    nonce = get_num_transactions( src_address )
    gas_price = get_gas_price_in_wei()
    
    start_gas = eval_startgas( src_address, contract_hash, value, b2h(call), gas_price )    
    nonce = int( nonce, 16 )
    gas_price = int( gas_price, 16 )
    start_gas = int( start_gas, 16 ) + 100000
    
    params = { "from" : "0x" + src_address,
               "to"   : "0x" + contract_hash,
               "gas"  : "0x" + str(start_gas),
               "gasPrice" : "0x" + str(gas_price),
               "value" : str(value),
               "data" : "0x" + b2h(call) }
    
    return_value = json_call( "eth_call", [params])
    return_value = h2b(return_value[2:]) # remove 0x
    return translator.decode(function_name, return_value)

def wait_for_confirmation( tx_hash ):
    params = None
    if use_ether_scan:
        params = { "txhash" : "0x" + tx_hash }
    else:
        params = "0x" + tx_hash
    while( True ):
        print "waiting for tx to complete (might take up to 1 minute)"
        result = json_call( "eth_getTransactionReceipt", [params] )
        if result is None:
            time.sleep(10)
            continue
        if not( result["blockHash"] is None ):
            print "tx completed"
            return result
        time.sleep(10)
        
    
# consts
private_keys = [ utils.sha3("post contract " + str(i)) for i in range(10) ]
ether_to_wei = int( 1000000000000000000 )
tx_cost = int( 2 * ether_to_wei / 100 )
min_balance = tx_cost * 10 # need to pay for gas
contract_hash = "ccf06b3bcebe61c5294995804fe5de724e56a680"
abi = "[{\"constant\":false,\"inputs\":[{\"name\":\"new_name\",\"type\":\"string\"}],\"name\":\"change_king_name\",\"outputs\":[],\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"is_king_for_sale\",\"outputs\":[{\"name\":\"\",\"type\":\"bool\"}],\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"myid\",\"type\":\"bytes32\"},{\"name\":\"result\",\"type\":\"string\"}],\"name\":\"__callback\",\"outputs\":[],\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"get_king_price\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_day\",\"type\":\"int8\"},{\"name\":\"_month\",\"type\":\"int8\"},{\"name\":\"_year\",\"type\":\"int16\"}],\"name\":\"date_string\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"is_king_found\",\"outputs\":[{\"name\":\"\",\"type\":\"bool\"}],\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"get_king_address\",\"outputs\":[{\"name\":\"\",\"type\":\"address\"}],\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"min_price\",\"type\":\"uint256\"}],\"name\":\"set_for_sale\",\"outputs\":[],\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_confirmation_number\",\"type\":\"string\"},{\"name\":\"_day\",\"type\":\"int8\"},{\"name\":\"_month\",\"type\":\"int8\"},{\"name\":\"_year\",\"type\":\"int16\"},{\"name\":\"_king_name\",\"type\":\"string\"}],\"name\":\"submit\",\"outputs\":[],\"type\":\"function\"},{\"constant\":false,\"inputs\":[],\"name\":\"buy_king\",\"outputs\":[],\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"king_of_returning_shirts\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"type\":\"function\"},{\"inputs\":[],\"type\":\"constructor\"}]" 


def get_account_balance( key ):
    url = "https://testnet.etherscan.io/api"
    payload = {"module" : "account",
               "action" : "balance",
               "tag" : "latest",
               "address" : "0x" + b2h( utils.privtoaddr(key) ), 
               "apikey" : ether_scan_api_key }
    response = requests.post( url, params=payload )
    balance = response.json()[ 'result' ]
    if balance is None:
        return 0
    return int(balance)

def suggest_private_keys( max_addresses ):
    num_found = 0
    for key in private_keys:
        if get_account_balance(key) > min_balance:
            print "0x" + b2h(key)
            num_found += 1
            if num_found == max_addresses:
                break
            
    return num_found
    

def norm_private_key( user_key ):
    if user_key[0] == "0" and user_key[1] == "x":
        return h2b(user_key[2:])
    else:
        return h2b(user_key)

def do_submit( key, conf_string, date_string, king_name ):
    (day,month,year) = date_string.split('/')
    if len(day) != 2 or len(month) != 2 or len(year) != 4:
        print "invalid date format (should be dd/mm/yyyy)"
        return False
    day = int(day)
    month = int(month)
    year = int(year)
    if( not call_function( key, tx_cost, contract_hash, abi, "submit", [conf_string,day,month,year,king_name] ) ):
        print "tx failed"
        return False
    #print "submitted with key = 0x" + b2h(key)
    return True
    
def print_king_name():
    # key does not matter
    name = call_const_function( private_keys[0], 0, contract_hash, abi, "king_of_returning_shirts", [] )[0]
    print name
    
def change_king_name( key, new_name ):
    if( not call_function( key, 0, contract_hash, abi, "change_king_name", [new_name] ) ):
        print "tx failed"
        return False
    return True

def set_price_for_sale( key, price_in_ether ):
    price_in_wei = int( price_in_ether * ether_to_wei )
    if( not call_function( key, 0, contract_hash, abi, "set_for_sale", [price_in_wei] ) ):
        print "tx failed"
        return False
    return True
     
def buy_king( key, price_in_ether ):
    price_in_wei = int( price_in_ether * ether_to_wei )
    if( not call_function( key, price_in_wei, contract_hash, abi, "buy_king", [] ) ):
        print "tx failed"
        return False
    return True

def usage():
    print "usage:  --show-king |--private-key=key | --suggest-private-key | --submit=\"RR123455IL 05/04/2016 name\" | --change-name=new_name | --set-price=7 | --buy=7"

def main():
    
    try:
        optlist, args = getopt.getopt(sys.argv[1:], 'h', ['private-key=', 'suggest-private-key', 'submit=', "change-name=", "set-price=", "buy=","show-king"])
    except getopt.GetoptError as err:
        # print help information and exit:
        print str(err)
        usage()
        sys.exit(2)

    key = None
    confirmation = None
    date = None
    submit = False
    sell = False
    price = None
    buy = False
    change_name = False
    new_name = None
    name = None
    
    for o,a in optlist:
        if "-h" in o:
            usage()
            exit(0)
        if "--show-king" in o:
            print_king_name()
            exit(0)                
        elif "--suggest-private-key" in o:
            print "possible keys:"
            if( suggest_private_keys(2) == 0 ):
                print "no more keys left"
            exit(0)
        elif "--private-key" in o:
            key = a
        elif "--submit" in o:
            submit = True
            (confirmation,date,name) = a.split(" ")
            if confirmation is None or date is None or name is None:
                print "Invalid input"
                usage()
        elif "--change-name" in o:
            change_name = True
            new_name = a
        elif "--set-price" in o:
            sell = True
            price = float(a)
        elif "--buy" in o:
            buy = True
            price = float(a)
            
    if key is None:
        print "private key must be provided"
        usage()
        exit(2)
    else:
        key = norm_private_key( key )
        
    if submit:
        if not do_submit(key, confirmation,date, name):
            print "submit failed"
            exit(2)
            
    elif change_name:
        if not change_king_name(key, new_name):
            print "change name failed"
            exit(2)
    
    elif sell:
        if not set_price_for_sale(key, price):
            print "set for sell failed"
            exit(2)
            
    elif buy:
        if not buy_king(key, price):
            print "buy failed"
            exit(2)
    else:
        print "invalid input"
        usage()
        exit(2)        
                    
if __name__ == "__main__":
    main()
    
    
