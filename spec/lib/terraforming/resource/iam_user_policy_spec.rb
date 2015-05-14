require "spec_helper"

module Terraforming
  module Resource
    describe IAMUserPolicy do
      let(:client) do
        Aws::IAM::Client.new(stub_responses: true)
      end

      let(:users) do
        [
          {
            path: "/",
            user_name: "hoge",
            user_id: "ABCDEFGHIJKLMN1234567",
            arn: "arn:aws:iam::123456789012:user/hoge",
            create_date: Time.parse("2015-04-01 12:34:56 UTC"),
            password_last_used: Time.parse("2015-04-01 15:00:00 UTC"),
          },
          {
            path: "/system/",
            user_name: "fuga",
            user_id: "OPQRSTUVWXYZA8901234",
            arn: "arn:aws:iam::345678901234:user/fuga",
            create_date: Time.parse("2015-05-01 12:34:56 UTC"),
            password_last_used: Time.parse("2015-05-01 15:00:00 UTC"),
          },
        ]
      end

      let(:hoge_policy) do
        {
          user_name: "hoge",
          policy_name: "hoge_policy",
          policy_document: "%7B%0A%20%20%22Version%22%3A%20%222012-10-17%22%2C%0A%20%20%22Statement%22%3A%20%5B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22Action%22%3A%20%5B%0A%20%20%20%20%20%20%20%20%22ec2%3ADescribe%2A%22%0A%20%20%20%20%20%20%5D%2C%0A%20%20%20%20%20%20%22Effect%22%3A%20%22Allow%22%2C%0A%20%20%20%20%20%20%22Resource%22%3A%20%22%2A%22%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D%0A",
        }
      end

      let(:fuga_policy) do
        {
          user_name: "fuga",
          policy_name: "fuga_policy",
          policy_document: "%7B%0A%20%20%22Version%22%3A%20%222012-10-17%22%2C%0A%20%20%22Statement%22%3A%20%5B%0A%20%20%20%20%7B%0A%20%20%20%20%20%20%22Action%22%3A%20%5B%0A%20%20%20%20%20%20%20%20%22ec2%3ADescribe%2A%22%0A%20%20%20%20%20%20%5D%2C%0A%20%20%20%20%20%20%22Effect%22%3A%20%22Allow%22%2C%0A%20%20%20%20%20%20%22Resource%22%3A%20%22%2A%22%0A%20%20%20%20%7D%0A%20%20%5D%0A%7D%0A",
        }
      end

      before do
        client.stub_responses(:list_users, users: users)
        client.stub_responses(:list_user_policies, [{ policy_names: %w(hoge_policy)}, { policy_names: %w(fuga_policy) }])
        client.stub_responses(:get_user_policy, [hoge_policy, fuga_policy])
      end

      describe ".tf" do
        it "should generate tf" do
          expect(described_class.tf(client)).to eq <<-EOS
resource "aws_iam_user_policy" "hoge_policy" {
    name   = "hoge_policy"
    user   = "hoge"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_user_policy" "fuga_policy" {
    name   = "fuga_policy"
    user   = "fuga"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

        EOS
        end
      end

      describe ".tfstate" do
        it "should generate tfstate" do
          expect(described_class.tfstate(client)).to eq JSON.pretty_generate({
            "version" => 1,
            "serial" => 1,
            "modules" => {
              "path" => [
                "root"
              ],
              "outputs" => {},
              "resources" => {
                "aws_iam_user_policy.hoge_policy" => {
                  "type" => "aws_iam_user_policy",
                  "primary" => {
                    "id" => "hoge:hoge_policy",
                    "attributes" => {
                      "id" => "hoge:hoge_policy",
                      "name" => "hoge_policy",
                      "policy" => "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": [\n        \"ec2:Describe*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": \"*\"\n    }\n  ]\n}\n",
                      "user" => "hoge",
                    }
                  }
                },
                "aws_iam_user_policy.fuga_policy" => {
                  "type" => "aws_iam_user_policy",
                  "primary" => {
                    "id" => "fuga:fuga_policy",
                    "attributes" => {
                      "id" => "fuga:fuga_policy",
                      "name" => "fuga_policy",
                      "policy" => "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": [\n        \"ec2:Describe*\"\n      ],\n      \"Effect\": \"Allow\",\n      \"Resource\": \"*\"\n    }\n  ]\n}\n",
                      "user" => "fuga",
                    }
                  }
                },
              }
            }
          })
        end
      end
    end
  end
end
