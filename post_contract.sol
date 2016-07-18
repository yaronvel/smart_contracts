// Ethereum + Solidity
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/ethereum/dapp-bin/blob/master/library/stringUtils.sol";

contract PostIL is usingOraclize {
  string destination_string; // destination
  int8 day; int8 month; int16 year;  // creation date
  string date;
  bool   allow_new_submissions;
  bool   king_found;
  address king_address;
  string  king_name;
  bool king_for_sale;
  uint price;
  bool in_payment;
  uint reward;
    
  function PostIL( ){
    oraclize_setProof(proofType_NONE);
    destination_string = "Ramle";
    day = 18;
    month = 7;
    year = 2016;
    allow_new_submissions = true;
    king_found = false;
    king_for_sale = false;
    in_payment = false;
    reward = 1020 finney;
  }
  
  function submit( string _confirmation_number, int8 _day, int8 _month, int16 _year, string _king_name ){
      if( ( ! allow_new_submissions ) || is_king_found() ) throw;

      // check that date is after creation
      if( _year > 3000 || _month > 12 || _day > 31 ) throw;

      if( _year < year ) throw;
      else if( _year == year )
      {
         if( _month < month ) throw;
	 else if( _month == month )
	 {
           if( _day < day ) throw;
         }
      }

      // check that has enough funds to call oraclize, and return the rest of the funds
      if( msg.value < 20 finney ) throw;
      if( ! msg.sender.send( msg.value - 20 finney) ) throw; // return the rest of the funds

      allow_new_submissions = false;
       
      date = date_string( _day, _month, _year );

      king_name = _king_name;
      king_address = msg.sender;
      // will become the king only when king_found is true

      update(0, _confirmation_number);

  }
  
  function __callback(bytes32 myid, string result) {
    if (msg.sender != oraclize_cbAddress()) throw;
    allow_new_submissions = true;
    // check date
    if ( indexOf( result, date ) >= 0 )
    {
       // check destination
       if( indexOf( result, destination_string ) >= 0 )
       {
          if( king_address.send( reward) ) king_found = true; // if payment faild, allow resubmit
       }
    }    
  }
    
  function update(uint delay, string _confirmation_number) internal {
      string memory post_base = "http://www.israelpost.co.il/itemtrace.nsf/trackandtraceJSON?openagent&lang=EN&itemcode=";
      string memory query = strConcat( "json(", post_base, _confirmation_number, ").itemcodeinfo");
      oraclize_query(delay, "URL", query, 900000 );
  }

  function change_king_name( string new_name ){
	if( ! is_king_found() ) throw;
        if( msg.sender != king_address ) throw;
        king_name = new_name;
  }

  function set_for_sale( uint min_price ){
        if ( ! is_king_found() ) throw;
        if( msg.sender != king_address ) throw;
        if( king_for_sale ) throw; // set price only once. if need to change, buy and sell again
	king_for_sale = true;
        price = min_price;
  }

  function buy_king( )
  {
        if( (! king_for_sale) || ( msg.value < price ) ) throw;	
        if( ! is_king_found() ) throw;
        if( king_address == msg.sender ) throw; // solidity fail when payer and payee are the same
        in_payment = true;
	bool send_val = king_address.send( msg.value );
 	in_payment = false;
        if( ! send_val ) throw; // payment failed
	king_address = msg.sender;
        king_for_sale = false;        
  }

  function king_of_returning_shirts() constant returns (string){
      if( is_king_found() ) return king_name;
      else return "no king";
  }    

  function is_king_found( ) constant returns (bool){
      return king_found;
  }

  function is_king_for_sale( ) constant returns (bool){
      return king_for_sale;
  }

  function get_king_price( ) constant returns (uint){
      return price;
  }

  function get_king_address( ) constant returns (address){
	if (!is_king_found() ) return address(0);
	return king_address;
  }
        
  function date_string( int8 _day, int8 _month, int16 _year ) constant returns (string) {
      // build date string
      string memory new_date = new string(10);
      bytes memory bnew_date = bytes(new_date);
      bnew_date[0] = (byte)((_day / 10) + 0x30); // 0x30 = '0'
      bnew_date[1] = (byte)((_day % 10) + 0x30);
      bnew_date[2] = '/';
      bnew_date[3] = (byte)((_month / 10) + 0x30);
      bnew_date[4] = (byte)((_month % 10) + 0x30);
      bnew_date[5] = '/';
      bnew_date[6] = (byte)((_year / 1000 ) + 0x30);
      bnew_date[7] = (byte)(( (_year / 100 ) % 10 ) + 0x30);
      bnew_date[8] = (byte)(( (_year / 10 ) % 10 ) + 0x30);
      bnew_date[9] = (byte)(( (_year / 1 ) % 10 ) + 0x30);

      return new_date;
  }

  function(){ throw; } // fallback function
}


