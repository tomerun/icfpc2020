require "./spec_helper"

describe MillerRabin do
  describe "is prime" do
    [2, 3, 5, 7, 11, 13, 17, 19, 23].each do |i|
      it "shows #{i} as prime" do
        MillerRabin.probably_prime(i, 100).should eq(true)
      end
    end

    [101, 103, 107, 109].each do |i|
      it "shows #{i} as prime" do
        MillerRabin.probably_prime(i, 100).should eq(true)
      end
    end

    [113, 1151, 13711, 81689, 211781, 997141, 2610737, 7968199, 10459103, 105453671].each do |i|
      it "shows #{i} as prime" do
        MillerRabin.probably_prime(i, 100).should eq(true)
      end
    end

    [122949031_u64, 122949041_u64].each do |i|
      it "shows #{i} as prime" do
        MillerRabin.probably_prime(i, 100).should eq(true)
      end
    end
  end

  describe "is not prime" do
    [4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20].each do |i|
      it "shows #{i} as not prime" do
        MillerRabin.probably_prime(i, 100).should eq(false)
      end
    end

    [1150, 1155, 1158, 5915587219_u64].each do |i|
      it "shows #{i} as not prime" do
        MillerRabin.probably_prime(i, 100).should eq(false)
      end
    end
  end
end
