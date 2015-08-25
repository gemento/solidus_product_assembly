require "spec_helper"

module Spree
  describe AssignPartToBundleForm do
    describe "#submit" do
      context "when given a quantity < 1" do
        it "is invalid" do
          product = build(:product)
          part_options = { count: -1 }

          command = AssignPartToBundleForm.new(product, part_options)

          expect(command).to be_invalid
        end
      end

      context "when given options for an existing assembly" do
        it "updates attributes on the existing assignment" do
          bundle = create(:product)
          part = create(:product, can_be_part: true)
          assignment = AssembliesPart.create(
            assembly_id: bundle.id,
            count: 1,
            part_id: part.id
          )

          part_options = { count: 2, id: assignment.id }

          command = AssignPartToBundleForm.new(bundle, part_options)
          command.submit
          assignment.reload

          expect(assignment.count).to be(2)
        end
      end

      context "when given options for an assembly that does not exist" do
        it "creates a new assembly part assignment with the provided options" do
          bundle = create(:product)
          part = create(:product, can_be_part: true)

          part_options = { count: 2, variant_id: part.id }

          command = AssignPartToBundleForm.new(bundle, part_options)

          expect { command.submit }.to change { AssembliesPart.count }.by(1)
        end
      end
    end
  end
end
