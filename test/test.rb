require 'minitest/autorun'
require 'date'

class Spese
  def initialize
    @totals = Hash.new(0)
    @raw_totals = Hash.new(0)
  end

  def add expense
    return if expense[:accrediti]
    data = expense[:data]
    @totals[[data.year, data.month]] += expense[:addebiti] unless expense[:excluded]
    @raw_totals[[data.year, data.month]] += expense[:addebiti]
  end

  def total(year, month)
    @totals[[year, month]]
  end

  def raw_total(year, month)
    @raw_totals[[year, month]]
  end

  def exclusions(year, month)
    raw_total(year, month) - total(year, month)
  end
end

class TotalsTest < MiniTest::Unit::TestCase

  def setup
    @spese = Spese.new
  end

  def test_total_no_expenses
    assert_equal 0, @spese.total(2016, 9)
  end

  def test_total_one_expense
    @spese.add expense( data: Date.new(2016,9,22), addebiti: 462.73 )
    assert_equal 462.73, @spese.total(2016, 9)
    assert_equal 0, @spese.total(2016, 8)
    assert_equal 0, @spese.total(2015, 9)
  end

  def test_total_two_expenses_same_month
    @spese.add expense( data: Date.new(2015,2,2), addebiti: 5.50 )
    @spese.add expense( data: Date.new(2015,2,5), addebiti: 2.00 )
    assert_equal 7.50, @spese.total(2015, 2)
  end

  def test_total_with_exclusions
    @spese.add expense( data: Date.new(2015,2,2), addebiti: 5.50, excluded: true )
    @spese.add expense( data: Date.new(2015,2,2), addebiti: 1.50, excluded: true )
    @spese.add expense( data: Date.new(2015,2,5), addebiti: 2.00, excluded: false )
    assert_equal 9.00, @spese.raw_total(2015, 2),  "raw total"
    assert_equal 2.00, @spese.total(2015, 2),      "total"
    assert_equal 7.00, @spese.exclusions(2015, 2), "exclusions"
  end

  def test_exclude_accrediti
    @spese.add expense( data: Date.new(2000,1,2), addebiti: nil, accrediti: 3.20 )
    assert_equal 0, @spese.total(2000, 1)
  end

  private

  def expense options
    default = {
      data: Date.new(2016,1,2),
      valuta: Date.new(2016,1,3),
      descrizione: "Pagamento Mav Via Internet Banking",
      addebiti: 3.14,
      accrediti: nil,
      descrizione_estesa: "Mav 05584524502744441"
    }
    default.merge options
  end
end