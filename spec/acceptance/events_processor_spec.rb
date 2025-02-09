require 'spec_helper_acceptance'

describe 'Event Forwarding' do
  is_pe = puppet_user == 'pe-puppet'
  let(:earliest) { Time.now.utc }

  context 'With event forwarding enabled', if: is_pe do
    before(:all) do
      server_agent_run(setup_manifest(with_event_forwarding: true))
    end

    context 'with orchestrator event_types set' do
      let(:report) do
        before_run = Time.now.utc
        puppetserver.run_shell("puppet task run facts --nodes #{host_name}")
        puppetserver.run_shell("#{EVENT_FORWARDING_CONFDIR}/collect_api_events.rb")
        after_run = Time.now.utc
        get_splunk_report(before_run, after_run, 'puppet:jobs')
      end

      it 'does not send report on first run' do
        puppetserver.run_shell('rm /etc/puppetlabs/pe_event_forwarding/pe_event_forwarding_indexes.yaml', expect_failures: true)
        count = report_count(report)
        expect(count).to be 0
      end

      it 'Successfully sends an orchestrator event to splunk' do
        # ensure the indexes.yaml file is created
        puppetserver.run_shell("#{EVENT_FORWARDING_CONFDIR}/collect_api_events.rb")
        count = report_count(report)
        expect(count).to be 1
      end

      it 'Sets event properties correctly' do
        data   = report[0]['result']
        event  = JSON.parse(data['_raw'])

        expect(data['source']).to                     eql('http:splunk_hec_token')
        expect(data['sourcetype']).to                 eql('puppet:jobs')
        expect(event['options']['scope']['nodes']).to eql([host_name])
        expect(event['options']['blah']).to           be_nil
        expect(event['environment']['name']).to       eql('production')
        expect(event['options']['transport']).to      be_nil
      end
    end
  end

  context 'with rbac event_types set' do
    it 'does not send report on first run'
    it 'Successfully sends an RBAC event to splunk'
    it 'Sets event properties correctly'
  end

  context 'with classifier event_types set' do
    it 'does not send report on first run'
    it 'Successfully sends a classifier event to splunk'
    it 'Sets event properties correctly'
  end

  context 'with pe_console event_types set' do
    it 'does not send report on first run'
    it 'Successfully sends a PE console event to splunk'
    it 'Sets event properties correctly'
  end

  context 'with code_manager event_types set' do
    it 'does not send report on first run'
    it 'Successfully sends a code manager event to splunk'
    it 'Sets event properties correctly'
  end
end
