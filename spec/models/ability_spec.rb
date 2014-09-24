require 'spec_helper'
require "cancan/matchers"

describe Ability do
  let(:su) {Ability.new(create(:superuser))}
  let(:om) {Ability.new(create(:ordermanageuser))}
  let(:im) {Ability.new(create(:issuemanageuser))}
  let(:bm) {Ability.new(create(:billmanageuser))}
  let(:pm) {Ability.new(create(:purchasemanageuser))}
  let(:u) {Ability.new(create(:user))}

  it "for admin" do
    su.should be_able_to(:manage, :all)
  end

  it "for OrderManager" do
    om.should be_able_to(:deliver, Order)
    om.should be_able_to(:manage, ManageController)
  end

  it "for IssueManage" do
    im.should be_able_to(:manage, Message)
    im.should be_able_to(:manage, Reply)
    im.should be_able_to(:manage, OrderAdjustment)
    im.should be_able_to(:refund, Order)
    im.should be_able_to(:change, Order)
    im.should be_able_to(:manage, ManageController)
  end

  it "for BillManager" do
    bm.should be_able_to(:manage, Deposit)
  end

  it "for PurchaseManager" do
    pm.should be_able_to(:manage, PurchaseProduct)
    pm.should be_able_to(:manage, Message)
    pm.should be_able_to(:manage, Reply)
  end

  it "for normal user" do
    u.should_not be_able_to(:manage, ManageController)
  end
end
