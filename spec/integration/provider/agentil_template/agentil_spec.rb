#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil_template'

describe Puppet::Type.type(:agentil_template).provider(:agentil), '(integration)' do
  include PuppetlabsSpec::Files

  let :resource_present do
    Puppet::Type.type(:agentil_template).new(
      :name        => 'System Template for system id 1',
      :ensure      => 'present',
      :system      => 'true',
      :monitors    => [ '1', '30' ],
      :jobs        => [ '79', '78', '600', '601' ]
    )
  end

  # resource does not exist, so applying the resource should
  # change nothing
  let :resource_absent do
    Puppet::Type.type(:agentil_template).new(
      :name   => 'no_such_template',
      :ensure => 'absent'
    )
  end

  # resource does exist, applying should remove it
  let :resource_destroy do
    Puppet::Type.type(:agentil_template).new(
      :name   => 'System Template for system id 3',
      :ensure => 'absent'
    )
  end

  let :resource_create do
    Puppet::Type.type(:agentil_template).new(
      :name        => 'System Template for system id 5',
      :ensure      => 'present',
      :system      => 'true',
      :monitors    => [ '1', '40', '30' ],
      :jobs        => [ '10', '16', '14', '3' ]
    )
  end

  let :resource_modify do
    Puppet::Type.type(:agentil_template).new(
      :name        => 'System Template for system id 2',
      :ensure      => 'present',
      :system      => 'true',
      :monitors    =>  [ '79', '600', '601' ],
      :jobs        =>  [ '1', '20', '24', '49' ]
    )
  end

  let :input do
    filename = tmpfilename('sapbasis_agentil.cfg')
    FileUtils.cp(my_fixture('sample.cfg'), filename)
    filename
  end

  let :catalog do
    Puppet::Resource::Catalog.new
  end

  def run_in_catalog(*resources)
    catalog.host_config = false
    resources.each do |resource|
      resource.expects(:err).never
      catalog.add_resource(resource)
    end
    catalog.apply
  end


  before :each do
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Util::Agentil.initvars
    Puppet::Util::Agentil.stubs(:filename).returns input
    Puppet::Type.type(:agentil_landscape).stubs(:defaultprovider).returns described_class
  end

  describe "ensure => absent" do
    describe "when resource is currently absent" do
      it "should do nothing" do
        state = run_in_catalog(resource_absent)
        File.read(input).should == File.read(my_fixture('sample.cfg'))
        state.changed?.should be_empty
      end
    end

    describe "when resource is currently present" do
      it "should remove the resource" do
        state = run_in_catalog(resource_destroy)
        File.read(input).should == File.read(my_fixture('output_remove.cfg'))
        state.changed?.should == [ resource_destroy ]
      end
    end
  end

  describe "ensure => present" do
    describe "when resource is currently absent" do
      it "should add the resource" do
        state = run_in_catalog(resource_create)
        File.read(input).should == File.read(my_fixture('output_add.cfg'))
        state.changed?.should == [ resource_create ]
      end
    end

    describe "when resource is currently present" do
      it "should do nothing if in sync" do
        state = run_in_catalog(resource_present)
        File.read(input).should == File.read(my_fixture('sample.cfg'))
        state.changed?.should be_empty
      end

      it "should modify attributes if not in sync" do
        state = run_in_catalog(resource_modify)
        File.read(input).should == File.read(my_fixture('output_modify.cfg'))
        state.changed?.should == [ resource_modify ]
      end
    end
  end
end
