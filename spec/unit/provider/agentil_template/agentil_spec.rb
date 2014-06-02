#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_template).provider(:agentil) do

  let :provider do
    described_class.new(
      :name             => 'NEW_TEMPLATE',
      :ensure           => :present,
      :agentil_template => template
    )
  end

  let :template do
    Puppet::Util::AgentilTemplate.new(1000001, template_element)
  end

  let :template_element do
    element = Puppet::Util::NimsoftSection.new('TEMPLATE1000000')
    element[:ID] = '1000001'
    element[:NAME] = 'NEW_TEMPLATE'
    element
  end

  let :resource do
    resource = Puppet::Type.type(:agentil_template).new(
      :name      => 'NEW_TEMPLATE',
      :ensure    => 'present',
      :system    => 'true',
      :jobs      => [ '122', '55' ],
      :monitors  => [ '22', '33' ]
    )
    resource.provider = provider
    resource
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        instance = described_class.new(:name => 'NEW_TEMPLATE', :ensure => :present)
        instance.should be_exists
      end

      it "should return false otherwise" do
        instance = described_class.new(:name => 'NEW_TEMPLATE')
        instance.should_not be_exists
      end
    end

    describe "create" do
      it "should add a new template" do
        resource
        Puppet::Util::Agentil.expects(:add_template).returns template
        template.expects(:name=).with('NEW_TEMPLATE')
        template.expects(:system_template=).with(:true)
        template.expects(:jobs=).with([ 122, 55 ])
        template.expects(:monitors=).with([ 22, 33 ])
        provider.create
      end

      it "should raise an error if the system is missing" do
        resource = Puppet::Type.type(:agentil_template).new(
          :name        => 'FOOBAR',
          :ensure      => :present
        )
        resource.provider = provider
        expect { provider.create }.to raise_error(Puppet::Error, 'Unable to create a new template without a system property')
      end
    end
    
    describe "destroy" do
      it "should delete a template" do
        resource
        Puppet::Util::Agentil.expects(:del_template).with(1000001)
        provider.destroy
      end

      it "should not complain about a missing system property" do
        resource = Puppet::Type.type(:agentil_user).new(
          :name   => 'NEW_TEMPLATE',
          :ensure => 'absent'
        )
        resource.provider = provider
        Puppet::Util::Agentil.expects(:del_template).with(1000001)
        provider.destroy
      end
    end
  end

  {:system => :system_template, :jobs => :jobs, :monitors => :monitors }.each_pair do |property, utilproperty|
    describe "when managing #{property}" do
      it "should delegate the getter method to the #{utilproperty} AgentilTemplate object" do
        template.expects(utilproperty).returns "value_for_#{property}"
        provider.send(property).should == "value_for_#{property}"
      end

      it "should delegate the setter method to the #{utilproperty} AgentilTemplate object" do
        template.expects("#{utilproperty}=".intern).with "value_for_#{property}"
        provider.send("#{property}=","value_for_#{property}")
      end
    end
  end

  describe "flush" do
    it "should sync the configuration file" do
      Puppet::Util::Agentil.expects(:sync)
      provider.flush
    end
  end
end
