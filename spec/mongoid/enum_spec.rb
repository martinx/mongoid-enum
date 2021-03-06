require 'spec_helper'

class User
  include Mongoid::Document
  include Mongoid::Enum

  enum :status, [:awaiting_approval, :approved, :banned]
  enum :roles, [:author, :editor, :admin], :multiple => true, :default => [], :required => false
end

describe Mongoid::Enum do
  let(:klass) { User }
  let(:instance) { User.new }
  let(:alias_name) { :status }
  let(:field_name) { :"_#{alias_name}" }
  let(:values) { [:awaiting_approval, :approved, :banned] }
  let(:multiple_field_name) { :"_roles" }

  describe "field" do
    it "is defined" do
      expect(klass).to have_field(field_name)
    end

    it "is aliased" do
      expect(instance).to respond_to alias_name
      expect(instance).to respond_to :"#{alias_name}="
      expect(instance).to respond_to :"#{alias_name}?"
    end

    describe "type" do
      context "when multiple" do
        it "is an array" do
          expect(klass).to have_field(multiple_field_name).of_type(Array)
        end

        it "validates using a custom validator" do
          expect(klass).to custom_validate(multiple_field_name).with_validator(Mongoid::Enum::Validators::MultipleValidator)
        end
      end

      context "when not multiple" do
        it "is a symbol" do
          expect(klass).to have_field(field_name).of_type(Symbol)
        end

        it "validates inclusion in values" do
          expect(klass).to validate_inclusion_of(field_name).to_allow(values)
        end
      end
    end
  end

  describe "constant" do
    it "is set to the values" do
      expect(klass::STATUS).to eq values
    end
  end
  
  describe "mapping" do
    it "is should be returns mappings hash" do
      expect(klass.statuses).to eq({awaiting_approval: 0, approved: 1, banned: 2})
    end
    
    it "is should be returns mapping index 1" do
      expect(klass.statuses[:approved]).to eq 1
    end
  end

  describe "accessors"do
    context "when singular" do
      describe "{{value}}!" do
        it "sets the value" do
          instance.save
          instance.banned!
          expect(instance.status).to eq :banned
        end
      end

      describe "{{value}}?" do
        context "when {{enum}} == {{value}}" do
          it "returns true" do
            instance.save
            instance.banned!
            expect(instance.banned?).to eq true
          end
        end
        context "when {{enum}} != {{value}}" do
          it "returns false" do
            instance.save
            instance.banned!
            expect(instance.approved?).to eq false
          end
        end
      end
    end

    context "when multiple" do
      describe "{{value}}!" do
        context "when field is nil" do
          it "creates an array containing the value" do
            instance.roles = nil
            instance.save
            instance.author!
            expect(instance.roles).to eq [:author]
          end
        end

        context "when field is not nil" do
          it "appends the value" do
            instance.save
            instance.author!
            instance.editor!
            expect(instance.roles).to eq [:author, :editor]
          end
        end
      end

      describe "{{value}}?" do
        context "when {{enum}} contains {{value}}" do
          it "returns true" do
            instance.save
            instance.author!
            instance.editor!
            expect(instance.editor?).to be_truthy
            expect(instance.author?).to be_truthy
          end
        end

        context "when {{enum}} does not contain {{value}}" do
          it "returns false" do
            instance.save
            expect(instance.author?).to be_falsey
          end
        end
      end
    end
  end

  describe "scopes" do
    context "when singular" do
      it "returns the corresponding documents" do
        instance.save
        instance.banned!
        expect(User.banned.to_a).to eq [instance]
      end
    end

    context "when multiple" do
      context "and only one document" do
        it "returns that document" do
          instance.save
          instance.author!
          instance.editor!
          expect(User.author.to_a).to eq [instance]
        end
      end

      context "and more than one document" do
        it "returns all documents with those values" do
          instance.save
          instance.author!
          instance.editor!
          instance2 = klass.create
          instance2.author!
          expect(User.author.to_a).to eq [instance, instance2]
          expect(User.editor.to_a).to eq [instance]
        end
      end
    end
  end

  describe "default values" do
    context "when not specified" do
      it "uses the first value" do
        instance.save
        expect(instance.status).to eq values.first
      end
    end

    context "when specified" do
      it "uses the specified value" do
        instance.save
        expect(instance.roles).to eq []
      end
    end
  end
end
