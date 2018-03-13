shared_examples 'an adapter' do |**options|
  let(:adapter) { described_class.name.split('::').last }

  let(:conn_options) { { headers: { 'X-Faraday-Adapter' => adapter } }.merge(options[:conn_options] || {}) }

  let(:adapter_options) do
    return [] unless options[:adapter_options]
    if options[:adapter_options].is_a?(Array)
      options[:adapter_options]
    else
      [options[:adapter_options]]
    end
  end

  let(:protocol) { ssl_mode? ? 'https' : 'http' }
  let(:remote) { "#{protocol}://example.com" }

  let(:conn) do
    conn_options[:ssl]           ||= {}
    conn_options[:ssl][:ca_file] ||= ENV['SSL_FILE']

    Faraday.new(remote, conn_options) do |conn|
      conn.request :multipart
      conn.request :url_encoded
      conn.response :raise_error
      conn.adapter described_class, *adapter_options
    end
  end

  let(:request_stub) { stub_request(http_method, remote) }

  after do |example|
    expect(request_stub).to have_been_requested unless example.skipped?
  end

  describe '#get' do
    let(:http_method) { :get }

    it_behaves_like 'a request method', multipart_support: false

    on_feature :body_on_get do
      it 'with body' do
        body = { bodyrock: 'true' }
        request_stub.with(body: body)
        conn.get('/') do |req|
          req.body = body
        end
      end
    end
  end

  describe '#post' do
    let(:http_method) { :post }

    it_behaves_like 'a request method'
  end

  describe '#put' do
    let(:http_method) { :put }

    it_behaves_like 'a request method'
  end

  describe '#patch' do
    let(:http_method) { :patch }

    it_behaves_like 'a request method', multipart_support: false
  end
end