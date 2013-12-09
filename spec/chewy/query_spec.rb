require 'spec_helper'

describe Chewy::Query do
  include ClassHelpers

  let(:products_index) do
    index_class(:products) do
      define_type(:product) do
        field :name, :age
      end
    end
  end

  subject { described_class.new(products_index, type: :product) }

  describe '#==' do
    let(:data) { 3.times.map { |i| {id: i.next.to_s, name: "Name#{i.next}", age: 10 * i.next}.stringify_keys! } }
    before { products_index.types['product'].import(data.map { |h| double(h) }) }

    specify { subject.query(match: 'hello').should == subject.query(match: 'hello') }
    specify { subject.query(match: 'hello').should_not == subject.query(match: 'world') }
    specify { subject.limit(10).should == subject.limit(10) }
    specify { subject.limit(10).should_not == subject.limit(11) }
    specify { subject.limit(2).should == subject.limit(2).to_a }
  end

  describe '#_request_query' do
    specify { subject.send(:_request_query).should == {} }
    specify { subject.filter(term: {field: 'hello'}).send(:_request_query)
      .should == {query: {filtered: {query: {match_all: {}}, filter: {term: {field: "hello"}}}}} }
    specify { subject.filter(term: {field: 'hello'}).filter(term: {field: 'world'}).send(:_request_query)
      .should == {query: {filtered: {query: {match_all: {}}, filter: {and: [
        {term: {field: "hello"}}, {term: {field: "world"}}
      ]}}}} }
    specify { subject.query(term: {field: 'hello'}).send(:_request_query)
      .should == {query: {term: {field: "hello"}}} }
    specify { subject.filter(term: {field: 'hello'}).query(term: {field: 'world'}).send(:_request_query)
      .should == {query: {filtered: {query: {term: {field: "world"}}, filter: {term: {field: "hello"}}}}} }
  end

  describe '#limit' do
    specify { subject.limit(10).should be_a described_class }
    specify { subject.limit(10).should_not == subject }
    specify { subject.limit(10).criteria.search.should include(size: 10) }
    specify { expect { subject.limit(10) }.not_to change { subject.criteria.search } }
  end

  describe '#offset' do
    specify { subject.offset(10).should be_a described_class }
    specify { subject.offset(10).should_not == subject }
    specify { subject.offset(10).criteria.search.should include(from: 10) }
    specify { expect { subject.offset(10) }.not_to change { subject.criteria.search } }
  end

  describe '#query' do
    specify { subject.query(match: 'hello').should be_a described_class }
    specify { subject.query(match: 'hello').should_not == subject }
    specify { subject.query(match: 'hello').criteria.query.should include(match: 'hello') }
    specify { expect { subject.query(match: 'hello') }.not_to change { subject.criteria.query } }
  end

  describe '#facets' do
    specify { subject.facets(term: {field: 'hello'}).should be_a described_class }
    specify { subject.facets(term: {field: 'hello'}).should_not == subject }
    specify { subject.facets(term: {field: 'hello'}).criteria.facets.should include(term: {field: 'hello'}) }
    specify { expect { subject.facets(term: {field: 'hello'}) }.not_to change { subject.criteria.facets } }
  end

  describe '#filter' do
    specify { subject.filter(term: {field: 'hello'}).should be_a described_class }
    specify { subject.filter(term: {field: 'hello'}).should_not == subject }
    specify { subject.filter(term: {field: 'hello'}).criteria.filters.should include(term: {field: 'hello'}) }
    specify { subject.filter([{term: {field: 'hello'}}, {term: {field: 'world'}}]).criteria.filters.should include(term: {field: 'hello'}) }
    specify { subject.filter([{term: {field: 'hello'}}, {term: {field: 'world'}}]).criteria.filters.should include(term: {field: 'world'}) }
    specify { expect { subject.filter(term: {field: 'hello'}) }.not_to change { subject.criteria.filters } }
  end

  describe '#order' do
    specify { subject.order(field: 'hello').should be_a described_class }
    specify { subject.order(field: 'hello').should_not == subject }
    specify { subject.order(field: 'hello').criteria.sort.should include(field: 'hello') }
    specify { expect { subject.order(field: 'hello') }.not_to change { subject.criteria.sort } }

    specify { subject.order(:field).criteria.sort.should == [:field] }
    specify { subject.order([:field1, :field2]).criteria.sort.should == [:field1, :field2] }
    specify { subject.order(field: :asc).criteria.sort.should == [{field: :asc}] }
    specify { subject.order({field1: {order: :asc}, field2: :desc}).order([:field3], :field4).criteria.sort.should == [{field1: {order: :asc}}, {field2: :desc}, :field3, :field4] }
  end

  describe '#reorder' do
    specify { subject.reorder(field: 'hello').should be_a described_class }
    specify { subject.reorder(field: 'hello').should_not == subject }
    specify { subject.reorder(field: 'hello').criteria.sort.should include(field: 'hello') }
    specify { expect { subject.reorder(field: 'hello') }.not_to change { subject.criteria.sort } }

    specify { subject.order(:field1).reorder(:field2).criteria.sort.should == [:field2] }
    specify { subject.order(:field1).reorder(:field2).order(:field3).criteria.sort.should == [:field2, :field3] }
    specify { subject.order(:field1).reorder(:field2).reorder(:field3).criteria.sort.should == [:field3] }
  end

  describe '#only' do
    specify { subject.only(:field).should be_a described_class }
    specify { subject.only(:field).should_not == subject }
    specify { subject.only(:field).criteria.fields.should include('field') }
    specify { expect { subject.only(:field) }.not_to change { subject.criteria.fields } }

    specify { subject.only(:field1, :field2).criteria.fields.should =~ ['field1', 'field2'] }
    specify { subject.only([:field1, :field2]).only(:field3).criteria.fields.should =~ ['field1', 'field2', 'field3'] }
  end
end
