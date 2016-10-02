contract SimpleMixer {
    
    struct Deal{
        mapping(address=>uint) deposit;
        uint                   depositSum;
        mapping(address=>bool) claims;
        uint                   claimSum;

        uint                   startTime;
        uint                   depositDurationInSec;
        uint                   claimDurationInSec;
        uint                   claimDepositInWei;
        uint                   claimValueInWei;
        
        bool                   active;
        bool                   violated;
    }
    
    Deal[]  _deals;
    uint    _houseFees;
    address _owner;
    
    function SimpleMixer(){
        _houseFees = 0;
        _owner = msg.sender;
    }
    
    function new_deal( uint _depositDurationInHours, uint _claimDurationInHours, uint _claimUnitValueInWei, uint _claimDepositInWei ) returns(uint){
        if( _depositDurationInHours == 0 || _claimDurationInHours == 0 ) throw;
        uint dealId = _deals.length;
        _deals.length++;
        _deals[dealId].depositSum = 0;
        _deals[dealId].claimSum = 0;
        _deals[dealId].startTime = now;
        _deals[dealId].depositDurationInSec = _depositDurationInHours * 1 hours;
        _deals[dealId].claimDurationInSec = _claimDurationInHours * 1 hours;
        _deals[dealId].claimDepositInWei = _claimDepositInWei;
        _deals[dealId].claimValueInWei = _claimUnitValueInWei;
        _deals[dealId].violated = false;
        _deals[dealId].active = true;
        return dealId;
    }
    
    modifier onlyActiveDeal(uint dealId) {
        if (!_deals[dealId].active)
            throw;
        _;
    }
    
    function makeDeposit( uint dealId ) onlyActiveDeal(dealId) {
        if( msg.value == 0 ) throw;
        
        Deal deal = _deals[dealId];
        if( deal.startTime + deal.depositDurationInSec > now ) throw;
        if( ( msg.value % deal.claimValueInWei ) > 0 ) throw;
        
        deal.depositSum += msg.value;
        deal.deposit[msg.sender] = msg.value;
    }
    
    function makeClaim( uint dealId ) onlyActiveDeal(dealId) {
        Deal deal = _deals[dealId];        
        if( deal.startTime + deal.depositDurationInSec <= now ) throw; // in deposit phase
        if( deal.startTime + deal.depositDurationInSec + deal.claimDurationInSec > now ) throw; // claim phase ended        
        
        if( msg.value != deal.claimDepositInWei ) throw;
        deal.claimSum += deal.claimValueInWei;
        deal.claims[msg.sender] = true;
        
        if( deal.claimSum > deal.depositSum ) deal.violated = true;
    }
    
    function withdraw( uint dealId ) onlyActiveDeal(dealId) {
        if( msg.value > 0 ) throw; // payment is not expected now
        Deal deal = _deals[dealId];        
        if( deal.startTime + deal.depositDurationInSec + deal.claimDurationInSec <= now ) throw; // claim phase wasn't end
        if( deal.violated ){
            uint depositValue = deal.deposit[msg.sender];
            if( depositValue == 0 ) throw;
            uint claimPayback = ( depositValue * deal.claimSum ) / (deal.depositSum * deal.claimValueInWei );
            
            deal.deposit[msg.sender] = 0; // invalidate user
            if( ! msg.sender.send(depositValue + claimPayback) ) throw;
        }
        else{
            if( ! deal.claims[msg.sender] ) throw;
            uint value = deal.claimDepositInWei + deal.claimValueInWei;
            uint fee = (deal.claimValueInWei * 5) / 1000;
            uint netValue = value - fee;
            _houseFees += fee;
            
            deal.claims[msg.sender] = false; // invalidate claim
            if( ! msg.sender.send(netValue) ) throw;
        }
    }
    
    function collectFees() {
        if( msg.sender != _owner ) throw;
        _houseFees = 0;
        if( ! msg.sender.send(_houseFees) ) throw;
    }
}

