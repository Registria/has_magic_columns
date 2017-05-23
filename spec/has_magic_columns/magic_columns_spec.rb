require 'spec_helper'
require 'pry-rails'


describe HasMagicColumns do

  context "on a single model" do
    before(:each) do
      @charlie = Person.create(name: "charlie")
    end

    it "initializes magic columns correctly" do
      expect(@charlie).not_to be(nil)
      expect(@charlie.class).to be(Person)
      expect(@charlie.magic_columns).not_to be(nil)
    end

    it "allows adding a magic columns" do
      @charlie.magic_columns.create(:name => 'salary')
      @charlie.magic_columns.length.should be(1)
    end

    it "allows setting and saving of magic attributes" do
      @charlie.magic_columns.create(:name => 'salary')
      @charlie.salary = 50000
      @charlie.save
      @charlie = Person.find(@charlie.id)
      @charlie.salary.should_not be_nil
    end

    it 'allows the use of write_attribute and read_attribute' do
      @charlie.magic_columns.create(:name => 'last_name')
      expect(@charlie.respond_to?(:last_name)).to be true
      expect(@charlie.respond_to?("last_name")).to be true
      @charlie.write_attribute(:last_name, "Roberts")
      @charlie.save
      @charlie = Person.find(@charlie.id)
      expect(@charlie.last_name).to eq("Roberts")
      expect(@charlie.read_attribute(:last_name)).to eq("Roberts")
    end

    it "allows datatype to be :date" do
      @charlie.magic_columns.create(:name => "birthday", :datatype => :date)
      @charlie.birthday = Date.today
      expect(@charlie.save).to be true
      expect(@charlie.birthday).to eq(Date.today)
    end

    it "allows datatype to be :datetime" do
      @charlie.magic_columns.create(:name => "signed_up_at", :datatype => :datetime)
      @charlie.signed_up_at = DateTime.now
      expect(@charlie.save).to be true
    end

    it "allows datatype to be :integer" do
      @charlie.magic_columns.create(:name => "age", :datatype => :integer)
      @charlie.age = 5
      expect(@charlie.save).to be true
      expect(@charlie.age).to eq(5)
    end

    it "allows datatype to be :check_box_boolean" do
      @charlie.magic_columns.create(:name => "retired", :datatype => :check_box_boolean)
      @charlie.retired = false
      expect(@charlie.save).to be true
      expect(@charlie.retired).to eq(false)
    end

    it "allows datatype to be :check_box_multiple" do
      @charlie.magic_columns.create(:name => "multiple", :datatype => "check_box_multiple")
      @charlie.multiple = ['1', '2', '3']
      expect(@charlie.save).to be true
      expect(@charlie.multiple).to eq(['1', '2', '3'])
    end

    it ":check_box_multiple returns array for single element" do
      @charlie.magic_columns.create(:name => "multiple", :datatype => "check_box_multiple")
      @charlie.multiple = ['1']
      expect(@charlie.save).to be true
      expect(@charlie.multiple).to eq(['1'])
    end

    it ":check_box_multiple properly updates attributes" do
      @charlie.magic_columns.create(:name => "multiple", :datatype => "check_box_multiple")
      @charlie.multiple = ['1', '2', '3']
      expect(@charlie.save).to be true
      expect(@charlie.multiple).to eq(['1', '2', '3'])
      @charlie.update_attributes(multiple: ['1'])
      expect(@charlie.multiple).to eq(['1'])
      @charlie.update_attributes(multiple: '2')
      expect(@charlie.multiple).to eq(['2'])
    end

    it "allows default to be set" do
      @charlie.magic_columns.create(:name => "bonus", :default => "40000")
      @charlie.bonus.should == "40000"
    end

    it "allows a pretty display name to be set" do
      @charlie.magic_columns.create(:name => "zip", :pretty_name => "Zip Code")
      @charlie.magic_columns.last.pretty_name.should == "Zip Code"
    end
  end

  context "in a parent-child relationship" do
    before(:each) do
      @account = Account.create(name: "important")
      @alice = User.create(name: "alice", account_id: @account.id)
    end

    it "initializes magic columns correctly" do
      @alice.should_not be_nil
      @alice.class.should be(User)
      @alice.magic_columns.should_not be_nil

      @account.should_not be_nil
      @account.class.should be(Account)
      @alice.magic_columns.should_not be_nil
    end

    it "allows adding a magic column to the child" do
      @alice.magic_columns.create(:name => 'salary')
      lambda{@alice.salary}.should_not raise_error
      lambda{@account.salary}.should_not raise_error
    end

    it "allows adding a magic column to the parent" do
      @account.magic_columns.create(:name => 'age')
      lambda{@alice.age}.should_not raise_error
    end

    it "sets magic columns for all child models" do
      @bob = User.create(name: "bob", account_id: @account.id)
      @bob.magic_columns.create(:name => 'birthday')
      lambda{@alice.birthday}.should_not raise_error
    end
  end
end
