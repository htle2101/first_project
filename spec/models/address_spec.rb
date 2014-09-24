require 'spec_helper'

describe Address do
  it "should return original province when province is not in the code hash" do
    c = stub_model(Address, :province => "normal")
    c.province.should == "normal"
  end

  it "should return full province name when province attribute is in the code hash" do
    c = stub_model(Address, :province => "CA-AB")
    c.province.should == "Alberta"
  end

  context "#state_dict" do
    it "should return us state when country_id is blank or country is usa" do
      c = stub_model(Address, :country_id => Country::USA)
      c.state_dict.should == Address::US_STATE
      c.country_id = nil
      c.state_dict.should == Address::US_STATE
    end

    it "should return ca state when country_id is canada" do
      c = stub_model(Address, :country_id => Country::CANADA)
      c.state_dict.should == Address::CANADA_STATE
    end
  end
end
