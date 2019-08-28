require "spec_helper"
require "pry-rails"


describe HasMagicColumns do

  context "on a single model" do
    let(:charlie) { Person.create(name: "charlie") }

    it "initializes magic columns correctly" do
      expect(charlie).to_not be nil
      expect(charlie.class).to eq Person
      expect(charlie.magic_columns).to_not be nil
    end

    it "allows adding a magic columns" do
      charlie.magic_columns.create(name: "salary")
      expect(charlie.magic_columns.length).to eq 1
    end

    it "allows setting and saving of magic attributes" do
      charlie.magic_columns.create(name: "salary")
      charlie.salary = 50000
      charlie.save
      expect(charlie.reload.salary).to eq "50000"
    end

    it "allows the use of write_attribute and read_attribute" do
      charlie.magic_columns.create(name: "last_name")
      expect(charlie.respond_to?(:last_name)).to be true
      expect(charlie.respond_to?("last_name")).to be true
      charlie.write_attribute(:last_name, "Roberts")
      charlie.save
      expect(charlie.reload.last_name).to eq "Roberts"
      expect(charlie.read_attribute(:last_name)).to eq "Roberts"
    end

    it "allows datatype to be :string" do
      charlie.magic_columns.create(name: "color", datatype: :date)
      charlie.color = "blue"
      expect(charlie.save).to be true
      expect(charlie.color).to eq "blue"
      charlie.update_attribute(:color, "red")
      expect(charlie.color).to eq "red"
      charlie.update_attribute(:color, ["green"])
      expect(charlie.color).to eq "green"
    end

    it "allows datatype to be :date" do
      charlie.magic_columns.create(name: "birthday", datatype: :date)
      charlie.birthday = Date.today
      expect(charlie.save).to be true
      expect(charlie.birthday).to eq Date.today
      charlie.update_attribute(:birthday, Date.today + 1.day)
      expect(charlie.birthday).to eq Date.today + 1.day
    end

    it "allows datatype to be :datetime" do
      charlie.magic_columns.create(name: "signed_up_at", datatype: :datetime)
      charlie.signed_up_at = DateTime.now
      expect(charlie.save).to be true
    end

    it "allows datatype to be :integer" do
      charlie.magic_columns.create(name: "age", datatype: :integer)
      charlie.age = 5
      expect(charlie.save).to be true
      expect(charlie.age).to eq 5
      charlie.update_attribute(:age, 4)
      expect(charlie.age).to eq 4
    end

    it "allows datatype to be :check_box_boolean" do
      charlie.magic_columns.create(name: "retired", datatype: :check_box_boolean)
      charlie.retired = false
      expect(charlie.save).to be true
      expect(charlie.retired).to be false
      charlie.update_attribute(:retired, true)
      expect(charlie.retired).to be true
      charlie.update_attribute(:retired, 1)
      expect(charlie.retired).to be true
      charlie.update_attribute(:retired, 0)
      expect(charlie.retired).to be false
      charlie.update_attribute(:retired, "1")
      expect(charlie.retired).to be true
      charlie.update_attribute(:retired, "0")
      expect(charlie.retired).to be false
    end

    it "allows default to be set" do
      charlie.magic_columns.create(name: "bonus", default: "40000")
      expect(charlie.bonus).to eq "40000"
    end

    it "allows a pretty display name to be set" do
      charlie.magic_columns.create(name: "zip", pretty_name: "Zip Code")
      expect(charlie.magic_columns.last.pretty_name).to eq "Zip Code"
    end

    it "touches parent on update" do
      charlie.magic_columns.create(name: "zip")
      expect { charlie.update_attributes(zip: "12345") }.to change { charlie.updated_at }
      expect { charlie.update_attributes(zip: "12345") }.to_not change { charlie.updated_at }
      expect { charlie.update_attributes(zip: "54321") }.to change { charlie.updated_at }
      expect { charlie.update_attributes(zip: "") }.to change { charlie.updated_at }
    end

    it "tracks magic changes" do
      charlie.magic_columns.create(name: "zip")
      expect(charlie.magic_changes).to be_empty
      expect(charlie.magic_changed?).to be false
      charlie.update_attributes(zip: "")
      expect(charlie.magic_changes).to be_empty
      expect(charlie.magic_changed?).to be false
      charlie.update_attributes(zip: 12345)
      expect(charlie.magic_changes).to eq "zip" => [nil, 12345]
      expect(charlie.magic_changed?).to be true
      charlie.update_attributes(zip: "54321")
      expect(charlie.magic_changes).to eq "zip" => ["12345", "54321"]
      expect(charlie.magic_changed?).to be true
      charlie.update_attributes(zip: nil)
      expect(charlie.magic_changes).to eq "zip" => ["54321", nil]
      expect(charlie.magic_changed?).to be true
      expect(charlie.reload.magic_changes).to be_empty
      expect(charlie.magic_changed?).to be false
    end

    context ":check_box_multiple" do
      before { charlie.magic_columns.create(name: "multiple", datatype: "check_box_multiple") }

      it "allows datatype to be :check_box_multiple" do
        charlie.multiple = ["1", "2", "3"]
        expect(charlie.save).to be true
        expect(charlie.multiple).to eq ["1", "2", "3"]
      end

      it ":check_box_multiple returns array for single element" do
        charlie.multiple = ["1"]
        expect(charlie.save).to be true
        expect(charlie.multiple).to eq ["1"]
      end

      it ":check_box_multiple properly updates attributes" do
        charlie.multiple = ["1", "2", "3"]
        expect(charlie.save).to be true
        expect(charlie.multiple).to eq ["1", "2", "3"]
        charlie.update_attributes(multiple: ["1"])
        expect(charlie.reload.multiple).to eq ["1"]
        charlie.update_attributes(multiple: "2")
        expect(charlie.reload.multiple).to eq ["2"]
      end
    end
  end

  context "in a parent-child relationship" do
    let(:account) { Account.create(name: "important") }
    let(:alice) { User.create(name: "alice", account: account) }
    let(:bob) { User.create(name: "bob", account: account) }

    it "initializes magic columns correctly" do
      expect(alice).to_not be nil
      expect(alice.class).to eq User
      expect(alice.magic_columns).to_not be nil

      expect(account).to_not be nil
      expect(account.class).to eq Account
      expect(account.magic_columns).to_not be nil
    end

    it "allows adding a magic column to the child" do
      alice.magic_columns.create(name: "salary")
      alice.salary = 50000
      alice.save
      expect(alice.reload.salary).to eq "50000"
    end

    it "does not repeat attributes for the same column" do
      alice.magic_columns.create(name: "color")
      alice.color = "red"
      alice.save
      expect(bob.color).to_not eq "red"
    end

    it "allows adding a magic column to the parent" do
      account.magic_columns.create(name: "age")
      expect { alice.age }.to_not raise_error
    end

    it "sets magic columns for all child models" do
      bob.magic_columns.create(name: "birthday")
      expect { alice.birthday }.to_not raise_error
    end
  end
end
