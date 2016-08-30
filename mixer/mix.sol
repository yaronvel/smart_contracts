contract mixer {

    struct anon_registeration{
        address sender;
        uint value;
        bool valid;
    }

    struct public_user{
        uint deposit;
        address addr;
        bool valid;
        uint revealed_deposit;
        anon_registeration[] registrations; // used only if there is violation
    }
    
    struct mixing_deal{
        uint start_time;
        public_user[] users; // must hold array to iterate them
        mapping (address=>uint) user_to_index_mapping;        
        anon_registeration[] registrations;
        mapping (address=>uint) registration_to_index_mapping;
        
        uint32 min_num_participants;
        uint   registration_deposit_size_in_wei;
        uint   phase_time_in_secs;
        
        uint   deposit_sum;
        uint   registration_sum;
        bool   violated;
    }
    
    mixing_deal[] deals;

    enum deal_state{
        invalid,
        
        initial_deposit,
        anonymous_registration,
        anonymous_withdraw,
        
        anonymous_revealing,
        public_withdraw_not_enough_parties,
        public_withdraw_violation
    }


    modifier non_payable {
        if (msg.value > 0 )
            throw;
        _
    }
    function mixer(){
        deals.length = 0;
    }

    function not_after_phase(mixing_deal deal, uint phase) constant private returns(bool){
        return deal.start_time + deal.phase_time_in_secs * phase >= now;
    }

    function get_deal_state(uint deal_id) constant returns(deal_state){
        if( deals.length <= deal_id ) return deal_state.invalid;
        mixing_deal deal = deals[ deal_id ];
        if( not_after_phase(deal, 1) ) return deal_state.initial_deposit;
        
        if( deal.users.length < deal.min_num_participants ) return deal_state.public_withdraw_not_enough_parties;
        
        if( not_after_phase(deal, 2) ) return deal_state.anonymous_registration;
        
        if( deal.violated ){
            if( not_after_phase(deal, 3) ) return deal_state.anonymous_revealing;
            // else - phase 4
            return deal_state.public_withdraw_violation;        
        }
        else{
            return deal_state.anonymous_withdraw;
        }
    }
    
    function create_new_deal(uint32 _min_num_participants,
                             uint   _registration_deposit_size_in_wei,
                             uint32 _phase_time_in_minutes ) non_payable returns (uint) {
        uint deal_id = deals.length;
        deals.length += 1;
        
                                 
        deals[ deal_id ].start_time = now;
        deals[ deal_id ].min_num_participants = _min_num_participants;
        deals[ deal_id ].registration_deposit_size_in_wei = _registration_deposit_size_in_wei;
        deals[ deal_id ].phase_time_in_secs = _phase_time_in_minutes * 1 minutes;
        
        deals[ deal_id ].deposit_sum = 0;
        deals[ deal_id ].registration_sum = 0;
        deals[ deal_id ].violated = false;

        return deal_id;
    }

    function make_initial_deposit( uint deal_id ){
        if( get_deal_state( deal_id ) != deal_state.initial_deposit ) throw;
        
        mixing_deal deal = deals[ deal_id ];
        uint user_index = deal.users.length;
        deal.users.length += 1;

        deal.users[ user_index ].deposit = msg.value;
        deal.users[ user_index ].addr = msg.sender;
        deal.users[ user_index ].revealed_deposit = 0;
        deal.users[ user_index ].valid = true;        
        
        deal.user_to_index_mapping[ msg.sender ] = user_index;
        
        deal.deposit_sum += msg.value;
    }
    
    function make_anonymous_registration( uint deal_id, uint amount_in_wei ){
        if( get_deal_state( deal_id ) != deal_state.anonymous_registration ) throw;
        if( amount_in_wei > 1024 * 1024 * 1024 ether ) throw; // prevent possible overflows

        
        mixing_deal deal = deals[ deal_id ];
        
        if( msg.value != deal.registration_deposit_size_in_wei ) throw;
        
        uint reg_id = deal.registrations.length;
        deal.registrations.length += 1;
        
        deal.registrations[ reg_id ].sender = msg.sender;
        deal.registrations[ reg_id ].value = amount_in_wei;
        deal.registrations[ reg_id ].valid = true;
        
        deal.registration_to_index_mapping[ msg.sender ] = reg_id;
        
        deals[ deal_id ].registration_sum += amount_in_wei;
        
        if( deals[ deal_id ].registration_sum > deal.deposit_sum ) deals[ deal_id ].violated = true;
    }
    
    function make_anonymous_withdraw(uint deal_id) non_payable{
        if( get_deal_state( deal_id ) != deal_state.anonymous_withdraw ) throw;
        uint reg_index = deals[ deal_id ].registration_to_index_mapping[ msg.sender ];
        anon_registeration reg = deals[ deal_id ].registrations[ reg_index ];
        if( ! reg.valid ) throw;

        // invalidate for next time
        reg.valid = false;
        
        uint value = reg.value + deals[ deal_id ].registration_deposit_size_in_wei;

        if( ! reg.sender.send( value ) ) throw;
    }    

    function reveal_registration( uint deal_id, address public_address ) non_payable{
        if( get_deal_state( deal_id ) != deal_state.anonymous_revealing ) throw;

        mixing_deal deal = deals[ deal_id ];
        
        // get registration
        uint reg_index = deal.registration_to_index_mapping[ msg.sender ];
        anon_registeration reg = deal.registrations[ reg_index ];
        if( ! reg.valid ) throw;

        // get user
        uint user_index = deal.user_to_index_mapping[ public_address ];
        public_user user = deal.users[ user_index ];
        if( ! user.valid ) throw;

        // assume no overflows        
        if( user.deposit >= user.revealed_deposit + reg.value ){
            user.registrations.length += 1;
            user.registrations[ user.registrations.length - 1 ] = reg;
            user.revealed_deposit += reg.value;
            return;
        }
        
        // else - replace with maximal value deposit
        uint max_index = 0;
        uint max_value = user.registrations[ 0 ].value;
        for ( uint index = 1; index < user.registrations.length; index += 1 ){
            if( user.registrations[ index ].value > max_value ){
                max_index = index;
                max_value = user.registrations[ index ].value;
            }
        }
        if( max_value > reg.value ) return; // ignore this registration
        // else - replace max with new reg
        user.registrations[ max_index ] = reg;
        user.revealed_deposit = user.revealed_deposit + reg.value - max_value;
    }

    function public_withdraw( uint deal_id ) non_payable{
        if( ( get_deal_state( deal_id ) != deal_state.public_withdraw_not_enough_parties ) &&
            ( get_deal_state( deal_id ) != deal_state.public_withdraw_violation ) ) throw;

        mixing_deal deal = deals[ deal_id ];
        uint user_index = deal.user_to_index_mapping[ msg.sender ];
        public_user user = deal.users[ user_index ];
        if( ! user.valid ) throw;
        
        uint value = user.deposit;

        if( get_deal_state( deal_id ) == deal_state.public_withdraw_violation ){
            value += user.registrations.length * deal.registration_deposit_size_in_wei;
        }

        user.valid = false;
        
        if( ! user.addr.send( value ) ) throw;
    }

}

